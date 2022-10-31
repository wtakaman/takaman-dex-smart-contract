// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20 {
    address public takamanDevTokenAddress;
    constructor (address _TakamanDevToken) ERC20("Takaman LP Token", "TK") {
        require(_TakamanDevToken != address(0), "Token address passed is a null address");
        takamanDevTokenAddress = _TakamanDevToken;
    }

    function getReserve() public view returns (uint) {
        return ERC20(takamanDevTokenAddress).balanceOf(address(this));
    }

    function addLiquidity(uint _amount) public payable returns (uint) {
        uint liquidity;
        uint ethBalance = address(this).balance;
        uint takamanDevTokenReserve = getReserve();
        ERC20 takamanDevToken = ERC20(takamanDevTokenAddress);

        if (takamanDevTokenReserve == 0) {
            takamanDevToken.transferFrom(msg.sender, address(this), _amount);
            liquidity = ethBalance;
            _mint(msg.sender, liquidity);
        } else {
            uint ethReserve = ethBalance - msg.value;
            uint takamanDevTokenAmount = (msg.value * takamanDevTokenReserve) / ethReserve;
            require(_amount >= takamanDevTokenAmount, "Amount of tokens sent is less than the minimum tokens required");

            takamanDevToken.transferFrom(msg.sender, address(this), takamanDevTokenAmount);
            liquidity = (totalSupply() * msg.value) / ethReserve;
            _mint(msg.sender, liquidity);
        }

        return liquidity;
    }

    function removeLiquidity(uint _amount) public returns (uint , uint) {
        require(_amount > 0, "amount should be greater than zero");
        uint ethReserve = address(this).balance;
        uint _totalSupply = totalSupply();
        uint ethAmount = (ethReserve * _amount) / _totalSupply;
        uint takamanDevTokenAmount = (getReserve() * _amount / _totalSupply);

        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(ethAmount);
        ERC20(takamanDevTokenAddress).transfer(msg.sender, takamanDevTokenAmount);
        return (ethAmount, takamanDevTokenAmount);
    }

    function getAmountOfTokens(uint256 inputAmount, uint inputReserve, uint256 outputReserve) public pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "invalid reserves");
        uint256 inputAmountWithFee = inputAmount * 99;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;
        return numerator / denominator;
    }

    function ethToTakamanDevToken(uint _minTokens) public payable {
        uint256 tokenReserve = getReserve();
        uint256 tokenBought = getAmountOfTokens(msg.value, address(this).balance - msg.value, tokenReserve);
        require(tokenBought >= _minTokens, "insufficient output amount");
        ERC20(takamanDevTokenAddress).transfer(msg.sender, tokenBought);
    }

    function takamanDevTokenToEth(uint _tokenSold, uint _minEth) public {
        uint256 tokenReserve = getReserve();
        uint ethBought = getAmountOfTokens(_tokenSold, tokenReserve, address(this).balance);
        require(ethBought >= _minEth, " insufficient output amount");
        ERC20(takamanDevTokenAddress).transferFrom(msg.sender, address(this), _tokenSold);
        payable(msg.sender).transfer(ethBought);
    }


}
