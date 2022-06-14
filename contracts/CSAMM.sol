//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;


contract CSAMM {

    /* INTERFACES */
    IERC20 public immutable token0;
    IERC20 public immutable token1;

    /* STATE VARIABLES */
    uint public reserve0;
    uint public reserve1;
    uint public totalSupply;
    uint public fee = 3;
    mapping(address => uint) public balanceOf;

    /* CONSTRUCTOR */
    constructor(address _token0, address _token1) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    /* MAIN FUNCTIONS */
    /* Trade one token for another */
    function swap(address _tokenIn, uint _amountIn) 
        external 
    {
        require(
            _tokenIn == address(token0) || _tokenIn == address(token1),
            'Invalid token'
        );

        // Check which token is in/out
        bool isToken0 = _tokenIn == address(token0);
        (IERC20 tokenIn, IERC20 tokenOut, uint resIn, uint resOut) = isToken0 ? 
        (token0, token1, reserve0, reserve1) : (token1, token0, reserve1, reserve0);

        // Transfer tokenIn
        tokenIn.transferFrom(msg.sender, address(this), _amountIn);
        uint amountIn = tokenIn.balanceOf(address(this)) - resIn;

        // Compute amountOut (incl. fees)
        uint amountOut;
        amountOut = (amountIn * (1000 - fee)) / 1000;

        // Update Reserves
        (uint res0, uint res1) = isToken0 ?
            (resIn + amountIn, resOut - amountOut) :
            (resOut + amountIn, resIn - amountOut);

        _update(res0, res1);

        // Transfer Token Out
        tokenOut.transfer(msg.sender, resOut);
    }

    function addLiquidity(uint _amount0, uint _amount1) 
        external returns (uint shares) 
    {
        // Transfer tokens in
        token0.transferFrom(msg.sender, address(this), _amount0);
        token1.transferFrom(msg.sender, address(this), _amount1);

        // Get balance
        uint bal0 = token0.balanceOf(address(this));
        uint bal1 = token1.balanceOf(address(this));

        // Get amounts in
        uint amount0 = bal0 - reserve0;
        uint amount1 = bal1 - reserve1;

        // Handle first deposit + find amount of shares to mint
        if (totalSupply == 0) {
            shares = amount0 + amount1;
        } else {
            shares = ((amount0 + amount1) * totalSupply) / (reserve1 + reserve0);
        }

        // Mint shares
        require(shares > 0, 'Shares must be greater than 0');
        _mint(msg.sender, shares);

        // Update reserves
        _update(bal0, bal1);
    }

    function removeLiquidity(uint _shares) external 
        returns (uint amount0, uint amount1) 
    {
        // Convert share amount to token amount
        amount0 = (reserve0 * _shares) / totalSupply;
        amount1 = (reserve1 * _shares) / totalSupply;

        // Burn shares
        _burn(msg.sender, _shares);

        // Update reserves
        _update(reserve0 - amount0, reserve1 - amount1);

        // Transfer out
        if (amount0 > 0) {
            token0.transfer(msg.sender, amount0);
        }
        if (amount1 > 0) {
            token1.transfer(msg.sender, amount1);
        }
    }

    /* HELPERS */
    function _mint(address _to, uint _amount) private {
        balanceOf[_to] += _amount;
        totalSupply += _amount;
    }

    function _burn(address _from, uint _amount) private {
        balanceOf[_from] -= _amount;
        totalSupply -= _amount;
    }

    function _update(uint _res0, uint _res1) private {
        reserve0 = _res0;
        reserve1 = _res1;
    } 
}


interface IERC20 {
    function totalSupply() external view returns (uint);
 
    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
}