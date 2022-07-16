// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

// SPDX-License-Identifier: MIT
// 1.pragma
pragma solidity ^0.8.8;

// 2 Imports
import "./PriceConverter.sol";

//FundMe__NotOwner()
error FundMe__NotOwner();

/** @title A contract for crowd fundion
 *   @author Ibrahim Ghasia
 *   @notice This contract is to demo a sample funding contract
 *   @dev This implements price feed as our library
 */
contract FundMe {
    using PriceConverter for uint256;

    uint256 public MINIMUM_USD = 10 * 1e18;
    // 	23515 <- without constant variable (gas used)
    // 	21371 <- constant variable (gas used)

    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;

    address private immutable i_owner;

    // 23644 <- without immutable (gas used)
    // 21508 <- immutable (gas used)

    AggregatorV3Interface private s_priceFeed;

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sneder is not owner!");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _; // <- Underscore represents doing the rest of the code
    }

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // What happends when someone sends this contract ETH without calling the fund function?
    // receive() external payable {
    //     fund();
    // }

    // fallback() external payable {
    //     fund();
    // }

    /**
     *   @notice This function funds this contract
     *   @dev This implements price feed as our library
     */
    function fund() public payable {
        // Want to be able to set a minimum fund in USD
        // 1. How do we send ETH to this contract?
        msg.value.getConversionRate(s_priceFeed);
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Didn't send enough"
        ); // 1e18 == 1 * 10 ** 18 == 1000000000000000000
        // What is revertiong?
        // Undo any action before, and send remaining gas back
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // Task Remaining:
        // 1) Reset the array
        s_funders = new address[](0);
        // 2) Withdraw the funds

        // 3 different ways to send eth or native currency
        // transfer
        // send
        // call

        // msg.sender => address type
        // payable(msg.sender) => payable address
        // payable(msg.sender).transfer(address(this).balance);  // <- Transfer

        // bool sendSuccess = payable(msg.sender).send(address(this).balance); // <- Send
        // require(sendSuccess, "Send Failed");

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }(""); // <- Call
        require(callSuccess, "Call Failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        // Note: mappings can't be in memory
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder)
        public
        view
        returns (uint256)
    {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
