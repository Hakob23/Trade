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
    uint                         public  initTime;
     
    mapping(address => uint)     public _addressToId;
    mapping(uint  => address)    public _IdToAddress;
    uint[]                       public _tradeVolumes;
    

    
    constructor(address _fuel, uint timer) public {
        factory = IJustSwapFactory(msg.sender);
        fuel = _fuel;
        initTime = now.add(timer) ;
    }
    
    // Returns Amount of fuel purchased
    function _sellTrxForFuel(IJustSwapExchange _exchangeFuel, uint _min_fuels, uint _deadline) private returns (uint) {
        exchangeFuel = IJustSwapExchange(factory.createExchange(fuel));
        return _exchangeFuel.trxToTokenTransferInput(_min_fuels, _deadline, msg.sender);
    }
    
    // Returns amount of TRX sold
    function _sellTrxForFixedFuel(IJustSwapExchange _exchangeFuel, uint _fuels_bought, uint _deadline) private returns (uint) {
        exchangeFuel = IJustSwapExchange(factory.createExchange(fuel));
        return _exchangeFuel.trxToTokenTransferOutput(_fuels_bought, _deadline, msg.sender);
    }
    
    // Returns amount of TRX purchased
    function _sellFuelForTrx(uint _fuels_sold, uint _min_trx, uint _deadline) private returns (uint) {
        exchangeFuel = IJustSwapExchange(factory.createExchange(fuel));
        return exchangeFuel.tokenToTrxTransferInput(_fuels_sold, _min_trx, _deadline,  msg.sender);
    }
    
    // Returns amount of fuel sold
    function _sellFuelForFixedTrx(uint _trx_bought, uint _max_fuels, uint _deadline) private returns (uint) {
        exchangeFuel = IJustSwapExchange(factory.createExchange(fuel));
        return exchangeFuel.tokenToTrxTransferOutput(_trx_bought, _max_fuels, _deadline, msg.sender);
    }
  
  
  
    
    // Trades fixed amount of TRX for fuel
    function tradeTrxForFuel(uint _min_fuels, uint trx_signed, uint _deadline) public payable {
        
        require(msg.value == trx_signed, 'signed trx value is incorrect');
        exchangeFuel = IJustSwapExchange(factory.createExchange(fuel));
        uint volume = _sellTrxForFuel(exchangeFuel, _min_fuels, _deadline);
        uint volumeTrx = exchangeFuel.getTrxToTokenOutputPrice(volume);
        msg.sender.transfer(msg.value.sub(volumeTrx));
        
        if(volume > 0) {
            uint traderId;
            if(_addressToId[msg.sender] == 0) {
            traderId = _tradeVolumes.length.add(1);
            _addressToId[msg.sender] = traderId;
            _IdToAddress[traderId] = msg.sender;
            _tradeVolumes.push(volume);
            } else {
            traderId = _addressToId[msg.sender].sub(1);
            _tradeVolumes[traderId] = _tradeVolumes[traderId].add(volume);
            }
        }
        
        
    }
    
    // Trades TRX for fixed amount of fuel
    function tradeTrxForFixedFuel(uint _fuels_bought, uint trx_signed, uint _deadline) public payable {
        
        require(msg.value == trx_signed, 'signed trx value is incorrect');
        exchangeFuel = IJustSwapExchange(factory.createExchange(fuel));
        uint volumeTrx = _sellTrxForFixedFuel(exchangeFuel, _fuels_bought, _deadline);
        msg.sender.transfer(msg.value.sub(volumeTrx));
        
        if(volumeTrx > 0) {
            uint traderId;
            if(_addressToId[msg.sender] == 0) {
                traderId = _tradeVolumes.length.add(1);
                _addressToId[msg.sender] = traderId;
                _IdToAddress[traderId] = msg.sender;
                _tradeVolumes.push(_fuels_bought);
            } else {
                traderId = _addressToId[msg.sender].sub(1);
                _tradeVolumes[traderId] = _tradeVolumes[traderId].add(_fuels_bought);
            }
        }
        
        
    }
    
    // Trades fixed amount of fuel for TRX
    function tradeFuelForTrx(uint _fuels_sold, uint _min_trx, uint _deadline) public  {
        
        ITRC20(fuel).transferFrom(msg.sender, address(this), _fuels_sold);
        exchangeFuel = IJustSwapExchange(factory.createExchange(fuel));
        uint volumeTrx = _sellFuelForTrx(_fuels_sold, _min_trx, _deadline);
        if(volumeTrx < _min_trx){
            ITRC20(fuel).transferFrom(address(this), msg.sender, _fuels_sold);
        } 
        
        if(volumeTrx >= _min_trx) {
            uint traderId;
            if(_addressToId[msg.sender] == 0) {
                traderId = _tradeVolumes.length.add(1);
                _addressToId[msg.sender] = traderId;
                _IdToAddress[traderId] = msg.sender;
                _tradeVolumes.push(_fuels_sold);
            } else {
                traderId = _addressToId[msg.sender].sub(1);
                _tradeVolumes[traderId] = _tradeVolumes[traderId].add(_fuels_sold);
            }
        }
        
        
    }

    // Trades fuel for fixed amount of TRX
    function tradeFuelForFixedTrx(uint _trx_bought, uint _max_fuels, uint _deadline) public  {
        
        ITRC20(fuel).transferFrom(msg.sender, address(this),_max_fuels);
        uint volume = _sellFuelForFixedTrx(_trx_bought, _max_fuels, _deadline);
        ITRC20(fuel).transferFrom(address(this), msg.sender, _max_fuels.sub(volume));
        
        if(volume > 0) {
            uint traderId;
            if(_addressToId[msg.sender] == 0) {
                traderId = _tradeVolumes.length.add(1);
                _addressToId[msg.sender] = traderId;
                _IdToAddress[traderId] = msg.sender;
                _tradeVolumes.push(volume);
            } else {
                traderId = _addressToId[msg.sender].sub(1);
                _tradeVolumes[traderId] = _tradeVolumes[traderId].add(volume);
            }
        }
        
    
    }
    
   
   
   
    // Returns amount of fuel purchased
    function _sellTokenForFuel(uint _tokens_sold, uint _min_fuels_bought, uint _min_trx_bought, uint _deadline, address _token_addr) private returns (uint) {
        IJustSwapExchange exchangeToken = IJustSwapExchange(factory.createExchange(_token_addr));
        return exchangeToken.tokenToTokenTransferInput(_tokens_sold, _min_fuels_bought, _min_trx_bought, _deadline, msg.sender, fuel);
    }
    
    // Returns amount of token sold
    function _sellTokenForFixedFuel(uint _fuels_bought, uint _max_tokens_sold, uint _max_trx_sold, uint _deadline, address _token_addr) private returns (uint) {
        IJustSwapExchange exchangeToken = IJustSwapExchange(factory.createExchange(_token_addr));
        return exchangeToken.tokenToTokenTransferOutput(_fuels_bought, _max_tokens_sold, _max_trx_sold, _deadline, msg.sender, fuel);
    }
    
    // Returns amount of token purchased
    function _sellFuelForToken(uint _fuels_sold, uint _min_tokens_bought, uint _min_trx_bought, uint _deadline, address _token_addr) private returns (uint) {
        exchangeFuel = IJustSwapExchange(factory.createExchange(fuel));
        return exchangeFuel.tokenToTokenTransferInput(_fuels_sold, _min_tokens_bought, _min_trx_bought, _deadline, msg.sender, _token_addr);
    }
    
    // Returns amount of fuel sold
    function _sellFuelForFixedToken(uint _tokens_bought, uint _max_fuels_sold, uint _max_trx_sold, uint _deadline, address _token_addr) private returns (uint) {
        exchangeFuel = IJustSwapExchange(factory.createExchange(fuel));
        return exchangeFuel.tokenToTokenSwapOutput(_tokens_bought, _max_fuels_sold, _max_trx_sold, _deadline, _token_addr);
    }
    
    
    // Trades a fixed amount of given token for fuel
    function tradeTokenForFuel(uint _tokens_sold, uint _min_fuels_bought, uint _min_trx_bought, uint _deadline, address _token_addr) public {
        
        ITRC20(_token_addr).transferFrom(msg.sender, address(this), _tokens_sold);
        uint volume = _sellTokenForFuel(_tokens_sold, _min_fuels_bought, _min_trx_bought, _deadline, _token_addr);
        if(volume < _min_fuels_bought) {
            ITRC20(_token_addr).transferFrom(address(this), msg.sender, _tokens_sold);
        }
        
        if(volume > 0) {
            uint traderId;
            if(_addressToId[msg.sender] == 0) {
                traderId =  _tradeVolumes.length.add(1);
                _addressToId[msg.sender] = traderId;
                _IdToAddress[traderId] = msg.sender;
                _tradeVolumes.push(volume);
            } else {
                traderId = _addressToId[msg.sender].sub(1);
                _tradeVolumes[traderId] = _tradeVolumes[traderId].add(volume);
            }
        }
        
        
    }
    
    // Trades a given token for fixed amount of fuel
    function tradeTokenForFixedFuel(uint _fuels_bought, uint _max_tokens_sold, uint _max_trx_sold, uint _deadline, address _token_addr) public {
        
        ITRC20(_token_addr).transferFrom(msg.sender, address(this), _max_tokens_sold);
        uint volumeToken = _sellTokenForFixedFuel(_fuels_bought, _max_tokens_sold, _max_trx_sold, _deadline, _token_addr);
        ITRC20(_token_addr).transferFrom(msg.sender, address(this), _max_tokens_sold.sub(volumeToken));
        
        if(volumeToken > 0) {
            uint traderId;
            if(_addressToId[msg.sender] == 0) {
                traderId = _tradeVolumes.length.add(1);
                _addressToId[msg.sender] = traderId;
                _IdToAddress[traderId] = msg.sender;
                _tradeVolumes.push(_fuels_bought);
            } else {
                traderId = _addressToId[msg.sender].sub(1);
                _tradeVolumes[traderId] = _tradeVolumes[traderId].add(_fuels_bought);
            }
        }
        
    }
    
    // Trades fixed amount of fuel for a given token
    function tradeFuelForToken(uint _fuels_sold, uint _min_tokens_bought, uint _min_trx_bought, uint _deadline, address _token_addr) public {
        
        ITRC20(fuel).transferFrom(msg.sender, address(this), _fuels_sold);
        uint volumeToken = _sellFuelForToken(_fuels_sold, _min_tokens_bought, _min_trx_bought, _deadline, _token_addr);
        if(volumeToken < _min_tokens_bought) {
            ITRC20(fuel).transferFrom(address(this), msg.sender, _fuels_sold);
        }
        
        if(volumeToken >= _min_tokens_bought) {
            uint traderId;
            if(_addressToId[msg.sender] == 0) {
                traderId = _tradeVolumes.length.add(1);
                _addressToId[msg.sender] = traderId;
                _IdToAddress[traderId] = msg.sender;
                _tradeVolumes.push(_fuels_sold);
            } else {
                traderId = _addressToId[msg.sender].sub(1);
                _tradeVolumes[traderId] = _tradeVolumes[traderId].add(_fuels_sold);
            }
        }
        
    }
    
    // Trades fuel for fixed amount of given token
    function tradeFuelForFixedToken(uint _tokens_bought, uint _max_fuels_sold, uint _max_trx_sold, uint _deadline, address _token_addr) public {
        ITRC20(fuel).transferFrom(msg.sender, address(this), _max_fuels_sold);
        uint volume = _sellFuelForFixedToken(_tokens_bought, _max_fuels_sold, _max_trx_sold, _deadline, _token_addr);
        ITRC20(fuel).transferFrom(address(this), msg.sender, _max_fuels_sold.sub(volume));
        
        if(volume > 0) {
            uint traderId;
            if(_addressToId[msg.sender] == 0) {
                traderId = _tradeVolumes.length.add(1);
                _addressToId[msg.sender] = traderId;
                _IdToAddress[traderId] = msg.sender;
                _tradeVolumes.push(volume);
            } else {
                traderId = _addressToId[msg.sender].sub(1);
                _tradeVolumes[traderId] = _tradeVolumes[traderId].add(volume);
            }
        }
        
    }
    
    
    // Send rewards and nulling the trade volumes after the reward distribution
    function sendRewards() public {
        require(now.sub(initTime) >= passedWeeks);
        require(now.sub(initTime) < 11 weeks);
        uint allTradeVolumes = 0;
        for(uint16 i = 0; i < _tradeVolumes.length; i++) {
            allTradeVolumes = allTradeVolumes.add(_tradeVolumes[i]);
        }
        for(uint16 i = 0; i < _tradeVolumes.length; i++) {
            uint week = (now.sub(initTime)).div(1 weeks);
            ITRC20 trcFuel = ITRC20(fuel);
            trcFuel.transfer(_IdToAddress[i+1], _tradeVolumes[i].div(allTradeVolumes).mul(weekToRewardValues[week.sub(1)]));
            _tradeVolumes[i] = 0;
        }
        passedWeeks = passedWeeks.add(1 weeks);
        allTradeVolumes = 0;
    }
    
    
}
