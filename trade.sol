pragma solidity 0.6.12;


import "./Ownable.sol";
import "./TRC20.sol";
import "./IJustSwapExchange.sol";
import "./IJustSwapFactory.sol";

contract Trade{
    
    uint256 constant public MAX_UINT256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    
    IJustswapFactory public factory;
    mapping(address => address) public fuelToTokenExchanges;
    mapping(address => address) public tokentoFuelExchanges;
    IJustSwapExchange exchangeTrx;
    address public fuel;
    // uint256 public nextConvertTime;
    // uint256 public lastPrice;
    
    constructor(IJustswapFactory _factory, address _fuel) public {
        factory = IJustswapFactory(TXk8rQSAvPvBBNtqSoY6nCfsXWCSSpTVQF);
        exchangeTrx = IJustswapFactory.createExchange(_fuel);
        fuel = _fuel;
    }
    
    function _sellTrxForFuel(uint256 _min_tokens, uint256 _deadline) private returns (uint256) {
       return exchangeTrx.trxToTokenSwapInput(_min_tokens, _deadline);
    }
    
    function _sellTrxForFixedFuel(uint256 _tokens_bought, uint256 _deadline) private returns (uint256) {
        return exchangeTrx.trxToTokenSwapOutput(_tokens_bought, _deadline);
    }
    
    function _sellFuelForTrx(uint256 _tokens_sold, uint256 _min_trx, uint256 _deadline) private returns (uint256) {
        return exchange.tokenToTrxSwapInput(_tokens_sold, _min_trx, _deadline);
    }
    
    function _sellFuelForFixedTrx(uint256 _trx_bought, uint256 _max_tokens, uint256 _deadline) private returns (uint256) {
        return exchange.tokenToTrxSwapOutput(_trx_bought, max_tokens, _deadline);
    }
    
    function _sellTokenForFuel() private returns (uint256);
    
    function _sellTokenForFixedFuel() private returns (uint256);
    
    function _sellFuelForToken() private returns (uint256);
    
    function _sellFuelForFixedToken() private returns (uint256);
    
    
    function tradeTrxForFuel(uint256 _min_tokens, uint256 _deadline) public returns (uint256) {
        return _sellTrxForFuel(_min_tokens, _deadline);
    }
    
    function tradeTrxForFixedFuel(uint256 _tokens_bought, uint256 _deadline) public returns(uint256) {
        return _sellTrxForFixedFuel(_tokens_bought, _deadline);
    }
    
    function tradeFuelForTrx(uint256 _tokens_sold, uint256 _min_trx, uint256 _deadline) public returns (uint256) {
        return _sellFuelForTrx(_tokens_sold, _min_trx, _deadline);
    }
    
    function tradeFuelForFixedTrx(uint256 _trx_bought, uint256 _max_tokens, uint256 _deadline) public returns (uint256) {
        return _sellFuelForFixedTrx(_trx_bought, _max_tokens, _deadline);
    }
    
    
}
