// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Let's win all the prize in the casino!

import {IERC20, ERC20, ERC20Wrapper} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Wrapper.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Base} from "../Base.sol";

contract CasinoToken is ERC20Wrapper, Ownable {
    constructor(address token)
        ERC20Wrapper(IERC20(token))
        ERC20(string.concat("Casino", ERC20(token).name()), string.concat("C", ERC20(token).symbol()))
    {}

    function depositFor(address account, uint256 amount) public override onlyOwner returns (bool) {
        _mint(account, amount);
        return true;
    }

    function withdrawTo(address account, uint256 amount) public override onlyOwner returns (bool) {
        _burn(account, amount);
        return true;
    }

    function bet(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }

    function get(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }
}

contract CasinoBank is Ownable {
    mapping(address => address) internal _tokenMap;
    mapping(address => uint256) internal _depositTime;
    address[] internal _tokenList;
    uint256 internal _tokenCount;

    modifier checkDeposit() {
        require(block.timestamp > _depositTime[msg.sender]);
        _depositTime[msg.sender] = block.timestamp;
        _;
    }

    function allowToken(address token) external onlyOwner {
        if (_tokenMap[token] == address(0)) {
            CasinoToken cToken = new CasinoToken(token);
            _tokenMap[token] = address(cToken);
            _tokenMap[address(cToken)] = token;
            _tokenList.push(token);
            _tokenCount++;
        }
    }

    function disallowToken(address token) external onlyOwner {
        address cToken = _tokenMap[token];
        if (cToken != address(0)) {
            _tokenMap[token] = address(0);
            _tokenMap[cToken] = address(0);
            _tokenCount--;
        }
    }

    // Gas consuming function, beware
    function listToken() external view returns (address[] memory) {
        address[] memory list = new address[](_tokenCount);
        uint256 j;
        for (uint256 i; i < _tokenList.length;) {
            address token = _tokenList[i];
            if (isAllowed(token)) {
                list[j] = token;
                unchecked {
                    j++;
                }
            }
            unchecked {
                i++;
            }
        }
        return list;
    }

    // Gas consuming function, beware
    function listCToken() external view returns (address[] memory) {
        address[] memory list = new address[](_tokenCount);
        uint256 j;
        for (uint256 i; i < _tokenList.length;) {
            address token = _tokenList[i];
            if (isAllowed(token)) {
                list[j] = _tokenMap[token];
                unchecked {
                    j++;
                }
            }
            unchecked {
                i++;
            }
        }
        return list;
    }

    function deposit(address token, uint256 amount) public checkDeposit {
        require(isAllowed(token));
        CasinoToken cToken = CasinoToken(_tokenMap[token]);
        cToken.depositFor(msg.sender, amount);
        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(address token, uint256 amount) public checkDeposit {
        require(isAllowed(token));
        CasinoToken cToken = CasinoToken(_tokenMap[token]);
        cToken.withdrawTo(msg.sender, amount);
        IERC20(token).transfer(msg.sender, amount);
    }

    function isAllowed(address token) public view returns (bool) {
        return _tokenMap[token] != address(0);
    }

    function isCToken(address cToken) public view returns (bool) {
        try CasinoToken(cToken).underlying() returns (IERC20 underlying) {
            return _tokenMap[address(underlying)] == cToken;
        } catch {
            return false;
        }
    }

    function CToken(address token) public view returns (address) {
        address cToken = _tokenMap[token];
        require(isCToken(cToken));
        return cToken;
    }
}

contract Casino is CasinoBank {
    mapping(address => uint256) internal _betTime;

    modifier checkPlay() {
        require(block.timestamp > _betTime[msg.sender]);
        _betTime[msg.sender] = block.timestamp;
        _;
    }

    function play(address token, uint256 amount) public checkPlay {
        _bet(token, amount);
        CasinoToken cToken = isCToken(token) ? CasinoToken(token) : CasinoToken(_tokenMap[token]);
        // play

        cToken.get(msg.sender, amount * slot());
    }

    function slot() public view returns (uint256) {
        unchecked {
            uint256 answer = uint256(blockhash(block.number - 1)) % 1000;
            uint256[3] memory slots = [(answer / 100) % 10, (answer / 10) % 10, answer % 10];
            if (slots[0] == slots[1] && slots[1] == slots[2]) {
                if (slots[0] == 7) {
                    return 100;
                } else {
                    return 10;
                }
            } else if (slots[0] == slots[1] || slots[1] == slots[2] || slots[0] == slots[2]) {
                return 3;
            } else {
                return 0;
            }
        }
    }

    function _bet(address token, uint256 amount) internal {
        require(isAllowed(token), "Token not allowed");
        CasinoToken cToken = CasinoToken(token);
        try cToken.bet(msg.sender, amount) {}
        catch {
            cToken = CasinoToken(_tokenMap[token]);
            deposit(token, amount);
            cToken.bet(msg.sender, amount);
        }
    }
}

contract CasinoAdvancedBase is Base {
    Casino public casino;

    address public immutable USDC;
    address public immutable WBTC;
    address public immutable WETH;
    address public immutable swap;

    constructor(
        uint256 startTime,
        uint256 endTime,
        uint256 fullScore,
        address USDC_,
        address WBTC_,
        address WETH_,
        address router02
    ) Base(startTime, endTime, fullScore) {
        USDC = USDC_;
        WBTC = WBTC_;
        WETH = WETH_;
        swap = router02;
    }

    function setup() external override {
        casino = new Casino();
        casino.allowToken(USDC);
        casino.allowToken(WBTC);
        casino.allowToken(WETH);
        IERC20(USDC).transfer(address(casino), 1_000_000e6);
        IERC20(WETH).transfer(address(casino), 1_000e18);
        IERC20(WBTC).transfer(address(casino), 1e8);
    }

    function solve() public override {
        require(IERC20(USDC).balanceOf(address(casino)) == 0);
        require(IERC20(WBTC).balanceOf(address(casino)) == 0);
        require(IERC20(WETH).balanceOf(address(casino)) == 0);
        super.solve();
    }
}
