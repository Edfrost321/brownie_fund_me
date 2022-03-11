// SPDX-License-Identifier: MIT

pragma solidity >=0.8;

// importing from npm/github
// https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// We want this contract to be able to accept
// some kind of payment
contract FundMe {

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    // later versions since the tutorial
    /* Visibility ( public / external ) is not needed for constructors anymore:
     To prevent a contract from being created, it can be marked abstract.
     This makes the visibility concept for constructors obsolete.
    */

    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }


    function fund() public payable {
        // $50
        uint256 minimumUSD = 50 * 10 ** 18;

        require(getConversionRate(msg.value) >= minimumUSD, "Insufficient Value");


        addressToAmountFunded[msg.sender] += msg.value;

        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        (,int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer * 10**10);
    }

    function getConversionRate(uint256 ethAmount) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 10**18;
        return ethAmountInUSD;
    }

    function getEntranceFee() public view returns (uint256) {
        // minimumUSD
        uint256 minimumUSD = 50 * 10 ** 18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return ((minimumUSD * precision) / price);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function withdraw() payable onlyOwner public {
        // only want the admin / owner to withdraw everything
        payable(msg.sender).transfer(address(this).balance);

        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}