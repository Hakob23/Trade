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
    
    event                        TokenPurchase(address indexed buyer, uint256 indexed trx_sold, uint256 indexed tokens_bought);
    event                        TrxPurchase(address indexed buyer, uint256 indexed tokens_sold, uint256 indexed trx_bought);
    event                        Approval(address indexed owner, address indexed spender, uint256 value);

    
    IJustSwapFactory             public  factory;
    IJustSwapExchange            public  exchangeFuel;
    address                      public  fuel;
    uint                         public  initTime;
     
    mapping(address => uint)     public addressToId;
    mapping(uint  => address)    public IdToAddress;
    uint[]                       public tradeVolumes;
    uint                         public lastTraderId;    

    
    constructor(address _fuel, address _factory, uint _timer) public {
        require(_fuel != address(0), 'Invalid address!');
        require(_factory != address(0), 'Invalid address!');
        factory = IJustSwapFactory(_factory);
        fuel = _fuel;
        initTime = now.add(_timer);
    }
    
    
     
     // Adds the volume of traded assets in fuels to the correspondent trader's index
    function _addTradingValue(uint _volume) private {
      if(addressToId[msg.sender] == 0) {
                lastTraderId = tradeVolumes.length.add(1);
                addressToId[msg.sender] = lastTraderId;
                IdToAddress[lastTraderId] = msg.sender;
                tradeVolumes.push(_volume);
        } else {
                uint traderId = addressToId[msg.sender].sub(1);
                tradeVolumes[traderId] = tradeVolumes[traderId].add(_volume);
        }
    }
  
  
    
  /**
   * @notice Convert fixed amount of TRX to Fuel && transfers Tokens to msg.user
   * @dev User specifies exact input (msg.value) && minimum output
   * @param _min_fuels Minimum Tokens bought.
   * @param _deadline Time after which this transaction can no longer be executed.
   */
    function tradeTrxForFuel(uint _min_fuels, uint _deadline) public payable {
        
        require(msg.value > 0, 'Trx is not assigned');
        
        if(exchangeFuel == IJustSwapExchange(address(0)))  {
            exchangeFuel = IJustSwapExchange(factory.getExchange(fuel));
        }
        
        uint volume = exchangeFuel.trxToTokenTransferInput(_min_fuels, _deadline, msg.sender);
        uint volumeTrx = exchangeFuel.getTrxToTokenOutputPrice(volume);
        
        msg.sender.transfer(msg.value.sub(volumeTrx));
        
        if(volume > 0) {
            emit TokenPurchase(msg.sender, volumeTrx, volume);
            _addTradingValue(volume);
        }
        
        
    }
    
    
    
   /**
   * @notice Convert TRX to Fixed Amount of Fuels && transfers to msg.sender.
   * @dev User specifies maximum input (msg.value) && exact output.
   * @param _fuels_bought Amount of fuels bought.
   * @param _deadline Time after which this transaction can no longer be executed.
   */
    function tradeTrxForFixedFuel(uint _fuels_bought, uint _deadline) public payable {
        
        require(msg.value > 0, 'Trx is not assigned');
        
        if(exchangeFuel == IJustSwapExchange(address(0)))  {
            exchangeFuel = IJustSwapExchange(factory.getExchange(fuel));
        }
        
        uint volumeTrx = exchangeFuel.trxToTokenTransferOutput(_fuels_bought, _deadline, msg.sender);
        
        msg.sender.transfer(msg.value.sub(volumeTrx));
        
        if(volumeTrx > 0) {
            emit TokenPurchase(msg.sender, volumeTrx, _fuels_bought);
            _addTradingValue(_fuels_bought);
        }
        
    }
    
    
    
    /**
   * @notice Convert Fixed Amount of Fuels to TRX && transfer TRX to msg.sender.
   * @dev User specifies exact input && minimum output.
   * @param _fuels_sold Amount of Tokens sold.
   * @param _min_trx Minimum TRX purchased.
   * @param _deadline Time after which this transaction can no longer be executed.
   */
    function tradeFuelForTrx(uint _fuels_sold, uint _min_trx, uint _deadline) public  {
        
        require(ITRC20(fuel).balanceOf(msg.sender) >= _fuels_sold, 'Not sufficient fuel balance!');
        ITRC20(fuel).approve(address(this), _fuels_sold);
        emit Approval(msg.sender, address(this), _fuels_sold);
        
        require(ITRC20(fuel).allowance(msg.sender, address(this)) >= _fuels_sold, 'Not enough approved fuels!');
        ITRC20(fuel).transferFrom(msg.sender, address(this), _fuels_sold);

        if(exchangeFuel == IJustSwapExchange(address(0)))  {
            exchangeFuel = IJustSwapExchange(factory.getExchange(fuel));
        }
        
        uint volumeTrx = exchangeFuel.tokenToTrxTransferInput(_fuels_sold, _min_trx, _deadline,  msg.sender);

        if(volumeTrx < _min_trx) {
            ITRC20(fuel).transferFrom(address(this), msg.sender, _fuels_sold);
        } else {
            emit TrxPurchase(msg.sender, _fuels_sold, volumeTrx);
            _addTradingValue(_fuels_sold);
        }
        
    }


    
  /**
   * @notice Convert Tokens to Fixed TRX && transfers TRX to msg.sender
   * @dev User specifies maximum input && exact output.
   * @param _trx_bought Amount of TRX purchased.
   * @param _max_fuels Maximum Fuels sold.
   * @param _deadline Time after which this transaction can no longer be executed.
   */
    function tradeFuelForFixedTrx(uint _trx_bought, uint _max_fuels, uint _deadline) public {
        
        require(ITRC20(fuel).balanceOf(msg.sender) >= _max_fuels, 'Not sufficient fuel balance!'); 
        ITRC20(fuel).approve(address(this), _max_fuels);
        emit Approval(msg.sender, address(this), _max_fuels);
        
        require(ITRC20(fuel).allowance(msg.sender, address(this)) >= _max_fuels, 'Not enough approved fuels!');
        ITRC20(fuel).transferFrom(msg.sender, address(this),_max_fuels);
        
        if(exchangeFuel == IJustSwapExchange(address(0)))  {
            exchangeFuel = IJustSwapExchange(factory.getExchange(fuel));
        }
        
        uint volume = exchangeFuel.tokenToTrxTransferOutput(_trx_bought, _max_fuels, _deadline, msg.sender);
        ITRC20(fuel).transferFrom(address(this), msg.sender, _max_fuels.sub(volume));
        
        if(volume > 0) {
            emit TrxPurchase(msg.sender, volume, _trx_bought);
            _addTradingValue(volume);
        }
    
    }
    
    
    /**
   * @notice Convert Fuels to Tokens (token_addr) && transfers
   *         Tokens (token_addr) to msg.sender.
   * @dev User specifies exact input && minimum output.
   * @param _tokens_sold Amount of Tokens sold.
   * @param _min_fuels_bought Minimum Tokens (token_addr) purchased.
   * @param _min_trx_bought Minimum TRX purchased as intermediary.
   * @param _deadline Time after which this transaction can no longer be executed.
   * @param _token_addr The address of the token being purchased.
   */
    function tradeTokenForFuel(uint _tokens_sold, uint _min_fuels_bought, uint _min_trx_bought, uint _deadline, address _token_addr) public {
        
        require(ITRC20(_token_addr).balanceOf(msg.sender) >= _tokens_sold, 'Not sufficient token balance!');
        ITRC20(_token_addr).approve(address(this), _tokens_sold);
        emit Approval(msg.sender, address(this), _tokens_sold);
        
        require(ITRC20(_token_addr).allowance(msg.sender, address(this)) >= _tokens_sold, 'Not enough approved tokens!');
        ITRC20(_token_addr).transferFrom(msg.sender, address(this), _tokens_sold);
        
        IJustSwapExchange exchangeToken = IJustSwapExchange(factory.getExchange(_token_addr));
        uint volume = exchangeToken.tokenToTokenTransferInput(_tokens_sold, _min_fuels_bought, _min_trx_bought, _deadline, msg.sender, fuel);
        uint volumeTrx = exchangeToken.getTrxToTokenOutputPrice(volume);
        
        if(volume < _min_fuels_bought) {
            ITRC20(_token_addr).transferFrom(address(this), msg.sender, _tokens_sold);
        } else {
            emit TokenPurchase(msg.sender, volumeTrx, volume);
            _addTradingValue(volume);
        }
        
        
    }
    
    
    /**
   * @notice Convert Tokens (token) to Tokens (token_addr) && transfers
   *         Tokens (token_addr) to recipient.
   * @dev User specifies maximum input && exact output.
   * @param _fuels_bought Amount of Tokens (token_addr) bought.
   * @param _max_tokens_sold Maximum Tokens (token) sold.
   * @param _max_trx_sold Maximum TRX purchased as intermediary.
   * @param _deadline Time after which this transaction can no longer be executed.
   * @param _token_addr The address of the token being purchased.
   */
    function tradeTokenForFixedFuel(uint _fuels_bought, uint _max_tokens_sold, uint _max_trx_sold, uint _deadline, address _token_addr) public {
        
        require(ITRC20(_token_addr).balanceOf(msg.sender) >= _max_tokens_sold, 'Not sufficient token balance!');
        ITRC20(_max_tokens_sold).approve(address(this), _max_tokens_sold);
        emit Approval(msg.sender, address(this), _max_tokens_sold);
        
        require(ITRC20(_token_addr).allowance(msg.sender, address(this)) >= _max_tokens_sold, 'Not enough approved tokens!');
        ITRC20(_token_addr).transferFrom(msg.sender, address(this), _max_tokens_sold);
        
        IJustSwapExchange exchangeToken = IJustSwapExchange(factory.getExchange(_token_addr));
        uint volumeToken = exchangeToken.tokenToTokenTransferOutput(_fuels_bought, _max_tokens_sold, _max_trx_sold, _deadline, msg.sender, fuel);
        uint volumeTrx = exchangeToken.getTrxToTokenOutputPrice(volumeToken);
        
        ITRC20(_token_addr).transferFrom(msg.sender, address(this), _max_tokens_sold.sub(volumeToken));
        
        if(volumeToken > 0) {
            emit TokenPurchase(msg.sender, volumeTrx, _fuels_bought);
            _addTradingValue(_fuels_bought);
        }
        
    }
    
    
    /**
   * @notice Convert Fuels to Tokens (token_addr) && transfers
   *         Tokens (token_addr) to recipient.
   * @dev User specifies exact input && minimum output.
   * @param _fuels_sold Amount of Tokens sold.
   * @param _min_tokens_bought Minimum Tokens (token_addr) purchased.
   * @param _min_trx_bought Minimum TRX purchased as intermediary.
   * @param _deadline Time after which this transaction can no longer be executed.
   * @param _token_addr The address of the token being purchased.
   */
    function tradeFuelForToken(uint _fuels_sold, uint _min_tokens_bought, uint _min_trx_bought, uint _deadline, address _token_addr) public {
        
        require(ITRC20(fuel).balanceOf(msg.sender) >= _fuels_sold, 'Not sufficient fuel balance!');
        ITRC20(fuel).approve(address(this), _fuels_sold);
        emit Approval(msg.sender, address(this), _fuels_sold);
        
        require(ITRC20(fuel).allowance(msg.sender, address(this)) >= _fuels_sold, 'Not enough approved fuels!');
        ITRC20(fuel).transferFrom(msg.sender, address(this), _fuels_sold);
        
        if(exchangeFuel == IJustSwapExchange(address(0)))  {
            exchangeFuel = IJustSwapExchange(factory.getExchange(fuel));
        }
        
        uint volumeToken = exchangeFuel.tokenToTokenTransferInput(_fuels_sold, _min_tokens_bought, _min_trx_bought, _deadline, msg.sender, _token_addr);
        uint volumeTrx = exchangeFuel.getTrxToTokenOutputPrice(_fuels_sold);
        
        
        if(volumeToken < _min_tokens_bought) {
            ITRC20(fuel).transferFrom(address(this), msg.sender, _fuels_sold);
        } else {
            emit TokenPurchase(msg.sender, volumeTrx, volumeToken);
            _addTradingValue(_fuels_sold);
        }
        
    }
    
    /**
   * @notice Convert Tokens (token) to Tokens (token_addr) && transfers
   *         Tokens (token_addr) to recipient.
   * @dev User specifies maximum input && exact output.
   * @param _tokens_bought Amount of Tokens (token_addr) bought.
   * @param _max_fuels_sold Maximum Tokens (token) sold.
   * @param _max_trx_sold Maximum TRX purchased as intermediary.
   * @param _deadline Time after which this transaction can no longer be executed.
   * @param _token_addr The address of the token being purchased.
   */
    function tradeFuelForFixedToken(uint _tokens_bought, uint _max_fuels_sold, uint _max_trx_sold, uint _deadline, address _token_addr) public {
        
        require(ITRC20(fuel).balanceOf(msg.sender) >= _max_fuels_sold, 'Not sufficient fuel balance!');
        ITRC20(fuel).approve(address(this), _max_fuels_sold);
        emit Approval(msg.sender, address(this), _max_fuels_sold);
        
        require(ITRC20(fuel).allowance(msg.sender, address(this)) >= _max_fuels_sold, 'Not enough approved fuels!');
        ITRC20(fuel).transferFrom(msg.sender, address(this), _max_fuels_sold);
        
        if(exchangeFuel == IJustSwapExchange(address(0)))  {
            exchangeFuel = IJustSwapExchange(factory.getExchange(fuel));
        }
        
        uint volume = exchangeFuel.tokenToTokenSwapOutput(_tokens_bought, _max_fuels_sold, _max_trx_sold, _deadline, _token_addr);
        uint volumeTrx = exchangeFuel.getTrxToTokenOutputPrice(volume);
        
        ITRC20(fuel).transferFrom(address(this), msg.sender, _max_fuels_sold.sub(volume));
        
        if(volume > 0) {
            emit TokenPurchase(msg.sender, volumeTrx, _tokens_bought);
            _addTradingValue(volume);
        }
        
    }
    
    
    // Sending rewards and nulling the trade volumes after the reward distribution
    function sendRewards() public {
        require(now.sub(initTime) >= passedWeeks, 'A week did not pass since the last reward time!');
        require(now.sub(initTime) < 11 weeks, 'Rewarding time has already ended!');
        
        uint allTradeVolumes = 0;
        
        for(uint i = 0; i < tradeVolumes.length; i++) {
            allTradeVolumes = allTradeVolumes.add(tradeVolumes[i]);
        }
        
        for(uint i = 0; i < tradeVolumes.length; i++) {
            uint week = (now.sub(initTime)).div(1 weeks);
            ITRC20(fuel).transfer(IdToAddress[i.add(1)], tradeVolumes[i].div(allTradeVolumes).mul(weekToRewardValues[week.sub(1)]));
            tradeVolumes[i] = 0;
        }
        passedWeeks = passedWeeks.add(1 weeks);
        allTradeVolumes = 0;
    }
    
    
}
