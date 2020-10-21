pragma solidity 0.6.12;  


interface IJustSwapExchange {
    
   // Trigger the event in trxToTokenSwapInput and trxToTokenSwapOutput
    event TokenPurchase(address indexed buyer, uint256 indexed trx_sold, uint256 indexed tokens_bought);
    
    
    // Trigger the event in tokenToTrxSwapInput, tokenToTrxSwapOutput, trxToTokenSwapInput and trxToTokenSwapOutput
    event TrxPurchase(address indexed buyer, uint256 indexed tokens_sold, uint256 indexed trx_bought);
    
    
    // Sell TRX (fixed amount) to buy token
    function trxToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable
    returns (uint256);
    
    
    // Sell TRX to buy token (fixed amount)
    function trxToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external
    payable returns(uint256);


    // Sell token to buy TRX (token is in a fixed amount)
    function tokenToTrxSwapInput(uint256 tokens_sold, uint256 min_trx, uint256 deadline) external returns (uint256);
    
    
    // Sell token to buy TRX (fixed amount)
    function tokenToTrxSwapOutput(uint256 trx_bought, uint256 max_tokens, uint256
    deadline) external returns (uint256);
    
    
    // Sell token1 and buy token2 (token1 is in a fixd amount). Since TRX functions as intermediary, both token1 and token2 need to have exchange addresses.
    function tokenToTokenSwapInput(uint256 tokens_sold, uint256 min_tokens_bought,
    uint256 min_trx_bought, uint256 deadline, address token_addr) external returns (uint256);
    
    // Sell token1 and buy token2 (token2 is in a fixd amount).
    function tokenToTokenSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold,
    uint256 max_trx_sold, uint256 deadline, address token_addr) external returns (uint256);
    
    // Sell token1 and buy token2 (token1 is in a fixd amount).Then, transfer the purchased token2 to the recipient's address
    function tokenToTokenTransferInput(uint256 tokens_sold, uint256 min_tokens_bought,
uint256 min_trx_bought, uint256 deadline, address recipient, address token_addr) external returns (uint256);
    
    //To know the amount of TRC20 token available for purchase through the amount of TRX sold
    function getTrxToTokenInputPrice(uint256 trx_sold) external view returns (uint256);
    
    //To know the amount of TRX to be paid through the amount of TRC20 token bought
    function getTrxToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256);
    
    //To know the amount of TRX available for purchase through the amount of TRC20 token sold
    function getTokenToTrxInputPrice(uint256 tokens_sold) external view returns (uint256);
    
    //To know the amount of TRC20 token to be paid through the amount of TRX bought
    function getTokenToTrxOutputPrice(uint256 trx_bought) external view returns (uint256);
    
    

}
