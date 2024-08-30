// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/proxy/Clones.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";


contract FailedLendingMarket {
    ChallFactory public challFactory;

    mapping(uint256 => Challenge) public instances;
    address public owner;

    constructor() {
        owner = msg.sender;
        challFactory = new ChallFactory(address(this));
    }

    function name() external pure returns (string memory) {
        return "CurtaLending";
    }

    function generate(address solver) public pure returns (uint256) {
        return uint256(keccak256(abi.encode(solver)));
    }

    function verify(uint256 seed, uint256) external view returns (bool) {
        return instances[seed].isSolved();
    }

    function deploy() external returns (address) {
        uint256 seed = generate(msg.sender);
        instances[seed] = Challenge(challFactory.createChallenge(seed, msg.sender));

        return address(instances[seed]);
    }
}

contract ChallFactory is Ownable {
    address immutable tokenImplementation;
    address immutable rebasingTokenImplementation;
    address immutable oracleImplementation;
    address immutable curtaLendingImplementation;
    address immutable challengeImplementation;

    constructor(address _curta) Ownable(_curta) {
        tokenImplementation = address(new CurtaToken());
        rebasingTokenImplementation = address(new CurtaRebasingToken());
        oracleImplementation = address(new Oracle());
        curtaLendingImplementation = address(new CurtaLending());
        challengeImplementation = address(new Challenge());
    }

    function createChallenge(uint256 seed, address player) external onlyOwner returns (address) {
        address usdClone = Clones.clone(tokenImplementation);
        address wethClone = Clones.clone(tokenImplementation);
        address rebasingWETHClone = Clones.clone(rebasingTokenImplementation);
        address oracleClone = Clones.clone(oracleImplementation);
        address curtaLendingClone = Clones.clone(curtaLendingImplementation);
        address challClone = Clones.clone(challengeImplementation);

        CurtaToken(usdClone).initialize("CurtaUSD", "USD", address(this));
        CurtaToken(wethClone).initialize("CurtaWETH", "WETH", address(this));
        CurtaRebasingToken(rebasingWETHClone).initialize("CurtaRebasingWETH", "RebasingWETH", wethClone, address(this));
        Oracle(oracleClone).initialize(address(this));
        CurtaLending(curtaLendingClone).initialize(address(this), oracleClone);
        Challenge(challClone).initialize(address(this), usdClone, wethClone, rebasingWETHClone, curtaLendingClone, seed);

        Oracle(oracleClone).setPrice(usdClone, 1e18);
        Oracle(oracleClone).setPrice(wethClone, 3000e18);
        Oracle(oracleClone).setPrice(rebasingWETHClone, 3100e18);

        CurtaLending(curtaLendingClone).setAsset(usdClone, true, 500, 0.8 ether, 0.9 ether, 0.05 ether);
        CurtaLending(curtaLendingClone).setAsset(wethClone, true, 300, 0.7 ether, 0.8 ether, 0.05 ether);
        CurtaLending(curtaLendingClone).setAsset(rebasingWETHClone, true, 300, 0.7 ether, 0.8 ether, 0.05 ether);

        CurtaToken(usdClone).mint(address(this), 10000 ether);
        CurtaToken(wethClone).mint(address(this), 20000 ether);
        CurtaToken(wethClone).approve(rebasingWETHClone, 10000 ether);
        CurtaRebasingToken(rebasingWETHClone).deposit(10000 ether);

        CurtaToken(usdClone).mint(player, 10000 ether);
        CurtaToken(wethClone).mint(player, 10000 ether);

        CurtaToken(usdClone).approve(curtaLendingClone, 10000 ether);
        CurtaLending(curtaLendingClone).depositLiquidity(usdClone, 10000 ether);
        CurtaToken(wethClone).approve(curtaLendingClone, 10000 ether);
        CurtaLending(curtaLendingClone).depositLiquidity(wethClone, 10000 ether);
        CurtaRebasingToken(rebasingWETHClone).approve(curtaLendingClone, 10000 ether);
        CurtaLending(curtaLendingClone).depositLiquidity(rebasingWETHClone, 10000 ether);

        return challClone;
    }
}

contract CurtaToken is ERC20Upgradeable, OwnableUpgradeable {
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory _name, string memory _symbol, address _initialOwner) external initializer {
        __ERC20_init(_name, _symbol);
        __Ownable_init(_initialOwner);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}

contract CurtaRebasingToken is ERC20Upgradeable, OwnableUpgradeable {
    IERC20 public underlyingToken;
    uint256 public unavaliableLiquidity;

    constructor() {
        _disableInitializers();
    }

    function initialize(string memory _name, string memory _symbol, address _underlyingToken, address _initialOwner)
        external
        initializer
    {
        __ERC20_init(_name, _symbol);
        __Ownable_init(_initialOwner);

        underlyingToken = IERC20(_underlyingToken);
    }

    function deposit(uint256 amount) external {
        _mint(msg.sender, amount * 1e18 / getExchangeRate());
        require(IERC20(underlyingToken).transferFrom(msg.sender, address(this), amount));
    }

    function withdraw(uint256 amount) external {
        require(super.balanceOf(msg.sender) >= amount);
        require(IERC20(underlyingToken).transfer(msg.sender, amount * getExchangeRate() / 1e18));
        _burn(msg.sender, amount);
    }

    function addYield(uint256 amount) external onlyOwner {
        require(IERC20(underlyingToken).transferFrom(msg.sender, address(this), amount));
    }

    function invest(uint256 amount) external onlyOwner {
        require(IERC20(underlyingToken).transfer(msg.sender, amount));
        unavaliableLiquidity += amount;
    }

    function payback(uint256 amount) external onlyOwner {
        require(IERC20(underlyingToken).transferFrom(msg.sender, address(this), amount));
        unavaliableLiquidity -= amount;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return super.balanceOf(account) * getExchangeRate() / 1e18;
    }

    function shareBalanceOf(address account) public view returns (uint256) {
        return super.balanceOf(account);
    }

    function getExchangeRate() public view returns (uint256) {
        if (super.totalSupply() == 0) {
            return 1e18;
        }
        return (underlyingToken.balanceOf(address(this)) + unavaliableLiquidity) * 1e18 / super.totalSupply();
    }

    function totalSupply() public view override returns (uint256) {
        return super.totalSupply() * getExchangeRate() / 1e18;
    }
}

struct UserInfo {
    address borrowAsset;
    uint256 liquidityAmount;
    uint256 collateralAmount;
    uint256 liquidityIndex;
    uint256 borrowIndex;
    uint256 claimableReward;
    uint256 totalDebt;
    uint256 principal;
}

struct AssetInfo {
    bool isAsset;
    uint256 totalLiquidity;
    uint256 avaliableLiquidity;
    uint256 totalDebt;
    uint256 totalPrincipal;
    uint256 interestRate;
    uint256 avaliableClaimableReward;
    uint256 borrowLTV;
    uint256 liquidationLTV;
    uint256 liquidationBonus;
    uint256 globalIndex;
    uint256 lastUpdateBlock;
}

contract Oracle is OwnableUpgradeable {
    mapping(address => uint256) private prices;

    constructor() {
        _disableInitializers();
    }

    function initialize(address _initialOwner) external initializer {
        __Ownable_init(_initialOwner);
    }

    function setPrice(address asset, uint256 price) external onlyOwner {
        prices[asset] = price;
    }

    function getPrice(address asset) external view returns (uint256) {
        return prices[asset];
    }
}


import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";



contract CurtaLending is OwnableUpgradeable {
    mapping(address => mapping(address => UserInfo)) public userInfo;
    mapping(address => AssetInfo) public assetInfo;

    Oracle public oracle;

    constructor() {
        _disableInitializers();
    }

    function initialize(address _initialOwner, address _oracle) external initializer {
        oracle = Oracle(_oracle);
        __Ownable_init(_initialOwner);
    }

    function setAsset(
        address _asset,
        bool _isAsset,
        uint256 _interestRate,
        uint256 _borrowLTV,
        uint256 _liquidationLTV,
        uint256 _liquidationBonus
    ) external onlyOwner {
        assetInfo[_asset].isAsset = _isAsset;
        assetInfo[_asset].interestRate = _interestRate;
        assetInfo[_asset].borrowLTV = _borrowLTV;
        assetInfo[_asset].liquidationLTV = _liquidationLTV;
        assetInfo[_asset].liquidationBonus = _liquidationBonus;
        assetInfo[_asset].lastUpdateBlock = block.number;
    }

    function depositCollateral(address asset, uint256 amount) external {
        require(assetInfo[asset].isAsset);
        accrueInterest(msg.sender, asset);

        UserInfo storage _userInfo = userInfo[msg.sender][asset];
        AssetInfo storage _assetInfo = assetInfo[asset];

        uint256 liquidityAmount = _userInfo.liquidityAmount;

        if (_userInfo.liquidityAmount < amount) {
            _userInfo.collateralAmount += amount;
            _userInfo.liquidityAmount = 0;
            _assetInfo.totalLiquidity -= liquidityAmount;
            _assetInfo.avaliableLiquidity -= liquidityAmount;
            require(IERC20(asset).transferFrom(msg.sender, address(this), amount - liquidityAmount));
        } else {
            _userInfo.collateralAmount += amount;
            _userInfo.liquidityAmount -= amount;
            _assetInfo.totalLiquidity -= amount;
            _assetInfo.avaliableLiquidity -= amount;
        }
    }

    function withdrawCollateral(address asset, uint256 amount) external {
        accrueInterest(msg.sender, asset);

        UserInfo storage _userInfo = userInfo[msg.sender][asset];
        AssetInfo storage _assetInfo = assetInfo[asset];

        uint256 collateralValue = (_userInfo.collateralAmount - amount) * oracle.getPrice(asset);
        uint256 borrowValue = _userInfo.totalDebt * oracle.getPrice(_userInfo.borrowAsset);
        require(collateralValue * _assetInfo.borrowLTV >= borrowValue * 1e18);

        if (amount == 0) {
            _userInfo.liquidityAmount += _userInfo.collateralAmount;
            _assetInfo.totalLiquidity += _userInfo.collateralAmount;
            _assetInfo.avaliableLiquidity += _userInfo.collateralAmount;
            _userInfo.collateralAmount = 0;
        } else {
            require(_userInfo.collateralAmount >= amount);
            _userInfo.liquidityAmount += amount;
            _userInfo.collateralAmount -= amount;
            _assetInfo.totalLiquidity += amount;
            _assetInfo.avaliableLiquidity += amount;
        }
    }

    function depositLiquidity(address asset, uint256 amount) external {
        require(assetInfo[asset].isAsset);
        accrueInterest(msg.sender, asset);

        UserInfo storage _userInfo = userInfo[msg.sender][asset];
        AssetInfo storage _assetInfo = assetInfo[asset];

        if (_userInfo.liquidityIndex == 0) {
            _userInfo.liquidityIndex = _assetInfo.globalIndex;
        }

        uint256 beforeBalance = IERC20(asset).balanceOf(address(this));
        require(IERC20(asset).transferFrom(msg.sender, address(this), amount));
        uint256 afterBalance = IERC20(asset).balanceOf(address(this)) - beforeBalance;

        _userInfo.liquidityAmount += afterBalance;
        _assetInfo.totalLiquidity += afterBalance;
        _assetInfo.avaliableLiquidity += afterBalance;
    }

    function withdrawLiquidity(address asset, uint256 amount) external {
        accrueInterest(msg.sender, asset);

        UserInfo storage _userInfo = userInfo[msg.sender][asset];
        AssetInfo storage _assetInfo = assetInfo[asset];

        require(_assetInfo.avaliableLiquidity >= amount);

        _userInfo.liquidityAmount -= amount;
        _assetInfo.totalLiquidity -= amount;
        _assetInfo.avaliableLiquidity -= amount;

        require(IERC20(asset).transfer(msg.sender, amount));
    }

    function borrow(address collateral, address borrowAsset, uint256 amount) external {
        require(assetInfo[borrowAsset].isAsset);
        UserInfo storage _userInfo = userInfo[msg.sender][collateral];
        require(_userInfo.borrowAsset == address(0) || _userInfo.borrowAsset == borrowAsset);

        if (_userInfo.borrowAsset == address(0)) {
            _userInfo.borrowAsset = borrowAsset;
        }

        accrueInterest(msg.sender, collateral);

        AssetInfo storage _assetInfo = assetInfo[borrowAsset];
        require(_assetInfo.avaliableLiquidity >= amount);

        if (_userInfo.borrowIndex == 0) {
            _userInfo.borrowIndex = _assetInfo.globalIndex;
        }

        uint256 collateralValue = _userInfo.collateralAmount * oracle.getPrice(collateral);
        uint256 borrowValue = amount * oracle.getPrice(borrowAsset);
        require(collateralValue * assetInfo[collateral].borrowLTV >= borrowValue * 1e18);

        _userInfo.totalDebt += amount;
        _userInfo.principal += amount;
        _assetInfo.totalDebt += amount;
        _assetInfo.totalPrincipal += amount;
        _assetInfo.avaliableLiquidity -= amount;

        require(IERC20(borrowAsset).transfer(msg.sender, amount));
    }

    function repay(address collateral, uint256 amount) external {
        accrueInterest(msg.sender, collateral);
        UserInfo storage _userInfo = userInfo[msg.sender][collateral];
        AssetInfo storage _assetInfo = assetInfo[_userInfo.borrowAsset];

        require(_userInfo.borrowAsset != address(0));

        uint256 borrowInterest = _userInfo.totalDebt - _userInfo.principal;

        if (_userInfo.totalDebt < amount) {
            amount = _userInfo.totalDebt;
        }

        _userInfo.totalDebt -= amount;
        _assetInfo.totalDebt -= amount;

        if (borrowInterest < amount) {
            _userInfo.principal -= amount - borrowInterest;
            _assetInfo.totalPrincipal -= amount - borrowInterest;
            _assetInfo.avaliableClaimableReward += borrowInterest;
            _assetInfo.avaliableLiquidity += amount - borrowInterest;
        } else {
            _assetInfo.avaliableClaimableReward += amount;
        }

        require(IERC20(_userInfo.borrowAsset).transferFrom(msg.sender, address(this), amount));
    }

    function liquidate(address user, address collateral, uint256 amount) external {
        accrueInterest(user, collateral);

        UserInfo storage _userInfo = userInfo[msg.sender][collateral];

        address asset = _userInfo.borrowAsset;

        // totalDebt * 0.5 < amount
        if (_userInfo.totalDebt < amount * 2) {
            amount = _userInfo.totalDebt / 2;
        }

        uint256 collateralValue = _userInfo.collateralAmount * oracle.getPrice(collateral);
        uint256 borrowValue = _userInfo.totalDebt * oracle.getPrice(asset);
        require(collateralValue * assetInfo[collateral].liquidationLTV <= borrowValue * 1e18);

        AssetInfo storage _assetInfo = assetInfo[_userInfo.borrowAsset];

        uint256 refundCollateral = amount * oracle.getPrice(asset) / oracle.getPrice(collateral)
            + amount * oracle.getPrice(asset) / oracle.getPrice(collateral) * _assetInfo.liquidationBonus / 1e18;

        if (refundCollateral > _userInfo.collateralAmount) {
            refundCollateral = _userInfo.collateralAmount;
        }

        _userInfo.collateralAmount -= refundCollateral;

        uint256 borrowInterest = _userInfo.totalDebt - _userInfo.principal;

        _userInfo.totalDebt -= amount;
        _assetInfo.totalDebt -= amount;

        if (borrowInterest < amount) {
            _userInfo.principal -= amount - borrowInterest;
            _assetInfo.totalPrincipal -= amount - borrowInterest;
            _assetInfo.avaliableClaimableReward += borrowInterest;
            _assetInfo.avaliableLiquidity += amount - borrowInterest;
        } else {
            _assetInfo.avaliableClaimableReward += amount;
        }

        require(IERC20(asset).transferFrom(msg.sender, address(this), amount));
        require(IERC20(collateral).transfer(msg.sender, refundCollateral));
    }

    function resetBorrowAsset(address collateral) external {
        accrueInterest(msg.sender, collateral);

        UserInfo storage _userInfo = userInfo[msg.sender][collateral];
        require(_userInfo.borrowAsset != address(0));
        require(_userInfo.principal == 0 && _userInfo.totalDebt == 0);

        _userInfo.borrowAsset = address(0);
        _userInfo.borrowIndex = 0;
    }

    function burnBadDebt(address user, address collateral) external {
        accrueInterest(user, collateral);

        UserInfo storage _userInfo = userInfo[user][collateral];
        require(_userInfo.collateralAmount == 0 && _userInfo.totalDebt != 0);

        AssetInfo storage _assetInfo = assetInfo[_userInfo.borrowAsset];

        require(IERC20(_userInfo.borrowAsset).transferFrom(msg.sender, address(this), _userInfo.totalDebt));

        _assetInfo.totalDebt -= _userInfo.totalDebt;
        _assetInfo.totalPrincipal -= _userInfo.principal;
        _assetInfo.avaliableClaimableReward += _userInfo.totalDebt - _userInfo.principal;
        _assetInfo.avaliableLiquidity += _userInfo.principal;
        _userInfo.totalDebt = 0;
        _userInfo.principal = 0;
    }

    function claimReward(address asset, uint256 amount) external {
        require(assetInfo[asset].avaliableClaimableReward >= amount);
        accrueInterest(msg.sender, asset);

        UserInfo storage _userInfo = userInfo[msg.sender][asset];
        require(_userInfo.claimableReward >= amount * 1e18);

        _userInfo.claimableReward -= amount * 1e18;
        assetInfo[asset].avaliableClaimableReward -= amount;

        require(IERC20(asset).transfer(msg.sender, amount));
    }

    function accrueInterest(address user, address asset) public {
        UserInfo storage _userInfo = userInfo[user][asset];

        if (_userInfo.liquidityIndex == 0 && _userInfo.borrowIndex == 0) {
            return;
        }

        address borrowAsset = _userInfo.borrowAsset;

        updateAsset(asset);
        updateAsset(borrowAsset);

        AssetInfo memory _assetInfo = assetInfo[asset];
        AssetInfo memory _borrowAssetInfo = assetInfo[borrowAsset];

        if (_userInfo.liquidityIndex != 0) {
            uint256 pending = _assetInfo.globalIndex - _userInfo.liquidityIndex;
            _userInfo.claimableReward += pending * 1e18 * _userInfo.liquidityAmount / _assetInfo.totalLiquidity;
            _userInfo.liquidityIndex = _assetInfo.globalIndex;
        }

        if (_userInfo.borrowIndex != 0) {
            uint256 pending = _borrowAssetInfo.globalIndex - _userInfo.borrowIndex;
            _userInfo.totalDebt += pending * _userInfo.principal / _borrowAssetInfo.totalPrincipal;
            _userInfo.borrowIndex = _borrowAssetInfo.globalIndex;

            if ((pending * _userInfo.principal) % _borrowAssetInfo.totalPrincipal != 0) {
                _userInfo.totalDebt += 1;
                _borrowAssetInfo.totalDebt += 1;
            }
        }
    }

    function updateAsset(address asset) public {
        AssetInfo storage _assetInfo = assetInfo[asset];

        if (block.number == _assetInfo.lastUpdateBlock) {
            return;
        }

        _assetInfo.globalIndex +=
            (block.number - _assetInfo.lastUpdateBlock) * _assetInfo.totalPrincipal * _assetInfo.interestRate / 10000;
        _assetInfo.totalDebt +=
            (block.number - _assetInfo.lastUpdateBlock) * _assetInfo.totalPrincipal * _assetInfo.interestRate / 10000;
        _assetInfo.lastUpdateBlock = block.number;
    }
}

contract Challenge is OwnableUpgradeable {
    CurtaToken public curtaUSD;
    CurtaToken public curtaWETH;
    CurtaRebasingToken public curtaRebasingETH;
    CurtaLending public curtaLending;

    uint256 public seed;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _initialOwner,
        address _curtaUSD,
        address _curtaWETH,
        address _curtaRebasingETH,
        address _curtaLending,
        uint256 _seed
    ) external initializer {
        __Ownable_init(_initialOwner);

        curtaUSD = CurtaToken(_curtaUSD);
        curtaWETH = CurtaToken(_curtaWETH);
        curtaRebasingETH = CurtaRebasingToken(_curtaRebasingETH);
        curtaLending = CurtaLending(_curtaLending);

        seed = _seed;
    }

    function isSolved() external view returns (bool) {
        require(
            curtaUSD.balanceOf(address(uint160(seed))) == 20000 ether
                && curtaWETH.balanceOf(address(uint160(seed))) == 30000 ether
        );
        return true;
    }
}
