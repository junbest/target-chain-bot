//"SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.1;

import "https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol";
import "https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IERC20.sol";

contract FrontRunner {
    
    address payable private manager;
    address payable private EOA = 0x842EA30128AB73F8493bCE23099C116AD0f732A9;//Replace this to your own address deployer account, otherwise you cannot drain back your coin
    address internal constant UNISWAP_ROUTER_ADDRESS = 0x10ED43C718714eb63d5aA57B78B54704E256024E;//Pancake Router
    
    IUniswapV2Router01 public uniswapRouter;

    event Received(address sender, uint amount);
    event UniswapEthBoughtActual(uint256 amount);
    event UniswapTokenBoughtActual(uint256 amount);
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    modifier restricted() {
        require(msg.sender == manager, "manager allowed only");
        _;
    }

    constructor() public {
        manager = msg.sender;
        uniswapRouter = IUniswapV2Router01(UNISWAP_ROUTER_ADDRESS);
    }
    
    function ethToToken(uint256 minTokens, uint256 deadline, address payable _uni, address tokenAddress) external restricted {
        uint256 ethBalance = address(this).balance;
        
        address[] memory paths = new address[](2);
        paths[0] = uniswapRouter.WETH();
        paths[1] = tokenAddress;
        
        uniswapRouter.swapExactETHForTokens {value: ethBalance}({amountOutMin: minTokens, path: paths, to: _uni, deadline: deadline});
        
    }

    function tokenToEth(uint256 tokensToSell, uint256 minEth, address[] calldata path, address to, uint256 deadline) external restricted {

        uniswapRouter.swapExactTokensForETH({ amountIn: tokensToSell, amountOutMin: minEth, path: path, to: to, deadline: deadline });
        
    }
    
    function kill() external restricted {
    selfdestruct(EOA);
    }

    function approve(uint tokenAmount, address tokenAddress) external restricted {
        IERC20 token = IERC20(tokenAddress);
        token.approve(address(uniswapRouter), tokenAmount);
    }

    function drainToken(ERC20 _token) external restricted {
        ERC20 token = ERC20(_token);
        uint tokenBalance = token.balanceOf(address(this));
        token.transfer(EOA, tokenBalance);
    }

}
    abstract contract ERC20 {
        function balanceOf(address account) external virtual view returns (uint256);
        function transfer(address recipient, uint256 amount) external virtual returns (bool);
        function approve(address spender, uint tokens) public virtual returns (bool success);
    }

    abstract contract Uniswap {
        function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external virtual payable returns (uint256  tokens_bought);
        //function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external virtual returns (uint256  eth_bought);
        function  swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external virtual returns (uint256  eth_bought);
    }

