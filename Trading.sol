pragma solidity 0.6.12;


import "./Ownable.sol";
import "./IJustSwapExchange.sol";
import "./IJustSwapFactory.sol";
import "./TRC20.sol";
import "./safemath.sol";



contract Trading is Ownable {
    
    using SafeMath for uint;
    
    uint                         public  passedWeeks = 1 weeks;
    uint[10]                     public  weekToRewardValues = [42000, 21000, 10500, 5250, 2625, 1715, 1715, 1715, 1715, 1715];
    
    IJustSwapFactory             public  factory;
    IJustSwapExchange            public  exchangeFuel;
    address                      public  fuel;
    mapping(address => uint)     public _addressToId;
    mapping(uint  => address)    public _IdToAddress;
    uint[]                       public _tradeVolumes;
    uint                         public  initTime;

    
    constructor(IJustSwapFactory _factory, address _fuel, uint timer) public onlyOwner {
        factory = _factory;
        exchangeFuel = IJustSwapExchange(factory.createExchange(_fuel));
        fuel = _fuel;
        initTime = now.add(timer) ;
    }
    
    // Returns Amount of fuel purchased
    function _sellTrxForFuel(uint _min_fuels, uint _deadline) private returns (uint) {
        return exchangeFuel.trxToTokenSwapInput(_min_fuels, _deadline);
    }
    
    // Returns amount of TRX sold
    function _sellTrxForFixedFuel(uint _fuels_bought, uint _deadline) private returns (uint) {
        return exchangeFuel.trxToTokenSwapOutput(_fuels_bought, _deadline);
    }
    
    // Returns amount of TRX purchased
    function _sellFuelForTrx(uint _fuels_sold, uint _min_trx, uint _deadline) private returns (uint) {
        return exchangeFuel.tokenToTrxSwapInput(_fuels_sold, _min_trx, _deadline);
    }
    
    // Returns amount of fuel sold
    function _sellFuelForFixedTrx(uint _trx_bought, uint _max_fuels, uint _deadline) private returns (uint) {
        return exchangeFuel.tokenToTrxSwapOutput(_trx_bought, _max_fuels, _deadline);
    }
  
    
    // Trades fixed amount of TRX for fuel
    function tradeTrxForFuel(uint _min_fuels, uint _deadline) public {
        if(_addressToId[msg.sender] == 0) {
            _addressToId[msg.sender] = _tradeVolumes.length + 1;
            _IdToAddress[_tradeVolumes.length + 1] = msg.sender;
            uint volume = _sellTrxForFuel(_min_fuels, _deadline);
            _tradeVolumes.push(volume);
        } else {
            uint volume = _sellTrxForFuel(_min_fuels, _deadline);
            _tradeVolumes[_addressToId[msg.sender] - 1] = _tradeVolumes[_addressToId[msg.sender] - 1].add(volume);
        }
        
    }
    
    // Trades TRX for fixed amount of fuel
    function tradeTrxForFixedFuel(uint _fuels_bought, uint _deadline) public {
        if(_addressToId[msg.sender] == 0) {
            _addressToId[msg.sender] = _tradeVolumes.length + 1;
            _IdToAddress[_tradeVolumes.length + 1] = msg.sender;
            _sellTrxForFixedFuel(_fuels_bought, _deadline);
            _tradeVolumes.push(_fuels_bought);
        } else {
            _sellTrxForFixedFuel(_fuels_bought, _deadline);
            _tradeVolumes[_addressToId[msg.sender] - 1] = _tradeVolumes[_addressToId[msg.sender] - 1].add(_fuels_bought);
        }
        
    }
    
    // Trades fixed amount of fuel for TRX
    function tradeFuelForTrx(uint _fuels_sold, uint _min_trx, uint _deadline) public {
        if(_addressToId[msg.sender] == 0) {
            _addressToId[msg.sender] = _tradeVolumes.length + 1;
            _IdToAddress[_tradeVolumes.length + 1] = msg.sender;
            _sellFuelForTrx(_fuels_sold, _min_trx, _deadline);
            _tradeVolumes.push(_fuels_sold);
        } else {
            _sellFuelForTrx(_fuels_sold, _min_trx, _deadline);
            _tradeVolumes[_addressToId[msg.sender] - 1] = _tradeVolumes[_addressToId[msg.sender] - 1].add(_fuels_sold);
        }
    }

    // Trades fuel for fixed amount of TRX
    function tradeFuelForFixedTrx(uint _trx_bought, uint _max_fuels, uint _deadline) public {
        if(_addressToId[msg.sender] == 0) {
            _addressToId[msg.sender] = _tradeVolumes.length + 1;
            _IdToAddress[_tradeVolumes.length + 1] = msg.sender;
            uint volume = _sellFuelForFixedTrx(_trx_bought, _max_fuels, _deadline);
            _tradeVolumes.push(volume);
        } else {
            uint volume = _sellFuelForFixedTrx(_trx_bought, _max_fuels, _deadline);
            _tradeVolumes[_addressToId[msg.sender] - 1] = _tradeVolumes[_addressToId[msg.sender] - 1].add(volume);
        }
    
    }
    
   
   
   
    // Returns amount of fuel purchased
    function _sellTokenForFuel(uint _tokens_sold, uint _min_fuels_bought, uint _min_trx_bought, uint _deadline, address _token_addr) private returns (uint) {
        IJustSwapExchange exchangeToken = IJustSwapExchange(factory.createExchange(_token_addr));
        return exchangeToken.tokenToTokenSwapInput(_tokens_sold, _min_fuels_bought, _min_trx_bought, _deadline, fuel);
    }
    
    // Returns amount of token Sold
    function _sellTokenForFixedFuel(uint _fuels_bought, uint _max_tokens_sold, uint _max_trx_sold, uint _deadline, address _token_addr) private returns (uint) {
        IJustSwapExchange exchangeToken = IJustSwapExchange(factory.createExchange(_token_addr));
        return exchangeToken.tokenToTokenSwapOutput(_fuels_bought, _max_tokens_sold, _max_trx_sold, _deadline, fuel);
    }
    
    // Returns amount of token purchased
    function _sellFuelForToken(uint _fuels_sold, uint _min_tokens_bought, uint _min_trx_bought, uint _deadline, address _token_addr) private returns (uint) {
        return exchangeFuel.tokenToTokenSwapInput(_fuels_sold, _min_tokens_bought, _min_trx_bought, _deadline, _token_addr);
    }
    
    // Returns amount of fuel sold
    function _sellFuelForFixedToken(uint _tokens_bought, uint _max_fuels_sold, uint _max_trx_sold, uint _deadline, address _token_addr) private returns (uint) {
        return exchangeFuel.tokenToTokenSwapOutput(_tokens_bought, _max_fuels_sold, _max_trx_sold, _deadline, _token_addr);
    }
    
    
    // Trades a fixed amount of given token for fuel
    function tradeTokenForFuel(uint _tokens_sold, uint _min_fuels_bought, uint _min_trx_bought, uint _deadline, address _token_addr) public  {
         if(_addressToId[msg.sender] == 0) {
            _addressToId[msg.sender] = _tradeVolumes.length + 1;
            _IdToAddress[_tradeVolumes.length + 1] = msg.sender;
            uint volume = _sellTokenForFuel(_tokens_sold, _min_fuels_bought, _min_trx_bought, _deadline, _token_addr);
            _tradeVolumes.push(volume);
        } else {
            uint volume = _sellTokenForFuel(_tokens_sold, _min_fuels_bought, _min_trx_bought, _deadline, _token_addr);
            _tradeVolumes[_addressToId[msg.sender] - 1] = _tradeVolumes[_addressToId[msg.sender] - 1].add(volume);
        }
        
    }
    
    // Trades a given token for fixed amount of fuel
    function tradeTokenForFixedFuel(uint _fuels_bought, uint _max_tokens_sold, uint _max_trx_sold, uint _deadline, address _token_addr) public {
         if(_addressToId[msg.sender] == 0) {
             _sellTokenForFixedFuel(_fuels_bought, _max_tokens_sold, _max_trx_sold, _deadline, _token_addr);
            _addressToId[msg.sender] = _tradeVolumes.length + 1;
            _IdToAddress[_tradeVolumes.length + 1] = msg.sender;
            _tradeVolumes.push(_fuels_bought);
        } else {
            _sellTokenForFixedFuel(_fuels_bought, _max_tokens_sold, _max_trx_sold, _deadline, _token_addr);
            _tradeVolumes[_addressToId[msg.sender] - 1] = _tradeVolumes[_addressToId[msg.sender] - 1].add(_fuels_bought);
        }
    }
    
    // Trades fixed amount of fuel for a given token
    function tradeFuelForToken(uint _fuels_sold, uint _min_tokens_bought, uint _min_trx_bought, uint _deadline, address _token_addr) public {
        if(_addressToId[msg.sender] == 0) {
             _sellFuelForToken(_fuels_sold, _min_tokens_bought, _min_trx_bought, _deadline, _token_addr);
            _addressToId[msg.sender] = _tradeVolumes.length + 1;
            _IdToAddress[_tradeVolumes.length + 1] = msg.sender;
            _tradeVolumes.push(_fuels_sold);
        } else {
            _sellFuelForToken(_fuels_sold, _min_tokens_bought, _min_trx_bought, _deadline, _token_addr);
            _tradeVolumes[_addressToId[msg.sender] - 1] = _tradeVolumes[_addressToId[msg.sender] - 1].add(_fuels_sold);
        }
    }
    
    // Trades fuel for fixed amount of given token
    function tradeFuelForFixedToken(uint _tokens_bought, uint _max_fuels_sold, uint _max_trx_sold, uint _deadline, address _token_addr) public {
        if(_addressToId[msg.sender] == 0) {
            _addressToId[msg.sender] = _tradeVolumes.length + 1;
            _IdToAddress[_tradeVolumes.length + 1] = msg.sender;
            uint volume = _sellFuelForFixedToken(_tokens_bought, _max_fuels_sold, _max_trx_sold, _deadline, _token_addr);
            _tradeVolumes.push(volume);
        } else {
            uint volume = _sellFuelForFixedToken(_tokens_bought, _max_fuels_sold, _max_trx_sold, _deadline, _token_addr);
            _tradeVolumes[_addressToId[msg.sender] - 1] = _tradeVolumes[_addressToId[msg.sender] - 1].add(volume);
        }
    }
    
    
    // Send rewards and nulling the trade volumes after the reward distribution
    function sendRewards() public {
        require(now - initTime >= passedWeeks);
        require(now - initTime < 11 weeks);
        uint allTradeVolumes = 0;
        for(uint16 i = 0; i < _tradeVolumes.length; i++) {
            allTradeVolumes = allTradeVolumes.add(_tradeVolumes[i]);
        }
        for(uint16 i = 0; i < _tradeVolumes.length; i++) {
            uint week = (now - initTime).div(1 weeks);
            ITRC20 trcFuel = ITRC20(fuel);
            trcFuel.transfer(_IdToAddress[i+1], _tradeVolumes[i]/allTradeVolumes * weekToRewardValues[week - 1]);
            _tradeVolumes[i] = 0;
        }
        passedWeeks = passedWeeks.add(1 weeks);
        allTradeVolumes = 0;
    }
    
    
}
