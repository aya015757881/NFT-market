// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./medium_token.sol";
import "./nft_ledger.sol";

contract NFTMarket {

    NFTLedger ledger;
    Medium medium;
    
    struct Order {
        uint256 tokenId;
        uint price;
    }

    enum OrderType {
        LIST,
        BID
    }

    mapping(address => Order[]) lists;
    mapping(address => Order[]) bids;

    function setLedger(address addr) public {
        ledger = NFTLedger(addr);
    }

    function setMedium(address addr) public {
        medium = Medium(addr);
    }

    function list(uint256 tokenId, uint price) public {
        address owner = ledger.getOwner(tokenId);
        require(owner == msg.sender, "You cannot list asset you do not own.");
        removeOrder(OrderType.LIST, owner, tokenId);
        lists[owner].push(Order(tokenId, price));
    }

    function unlist(uint256 tokenId) public {
        address owner = ledger.getOwner(tokenId);
        require(owner == msg.sender, "You cannot unlist asset you do not own.");
        removeOrder(OrderType.LIST, owner, tokenId);
    }

    function bid(uint256 tokenId, uint price) public {
        removeOrder(OrderType.BID, msg.sender, tokenId);
        bids[msg.sender].push(Order(tokenId, price));
    }

    function unbid(uint256 tokenId) public {
        removeOrder(OrderType.BID, msg.sender, tokenId);
    }

    function sell(address bidder, uint256 tokenId) public {
        // this function will surely update bids
        require(msg.sender == ledger.getOwner(tokenId), "You can not sell token you do not own");
        (bool get, Order memory order) = getOrder(OrderType.BID, bidder, tokenId);
        if (!get)
            revert("No matching bid.");
        ledger.transferFrom(msg.sender, bidder, tokenId);
        medium.transferFrom(bidder, msg.sender, order.price);
        removeOrder(OrderType.BID, bidder, tokenId);
    }

    function buy(address lister, uint256 tokenId) public {
        // this function will surely update lists
        (bool get, Order memory order) = getOrder(OrderType.LIST, lister, tokenId);
        if (!get)
            revert("No matching list");
        ledger.transferFrom(lister, msg.sender, tokenId);
        medium.transferFrom(msg.sender, lister, order.price);
        removeOrder(OrderType.LIST, lister, tokenId);
    }

    function getLists(address lister) public view returns (Order[] memory) {
        return lists[lister];
    }

    function getBids(address bidder) public view returns (Order[] memory) {
        return bids[bidder];
    }

    function ownership_altered(address owner, uint256 tokenId) public {
        // this function is likely to update lists or bids
        removeOrder(OrderType.LIST, owner, tokenId);
    }

    function getOrder(OrderType t, address maker, uint256 tokenId) internal view returns (bool, Order memory) {
        Order[] storage orders;
        if (t == OrderType.LIST)
            orders = lists[maker];
        else
            orders = bids[maker];
        for (uint i = 0; i < orders.length; i++)
            if (tokenId == orders[i].tokenId)
                return (true, orders[i]);
        return (false, Order(0, 0));
    }

    function removeOrder(OrderType t, address maker, uint256 tokenId) internal returns (bool) {
        Order[] storage orders;
        if (t == OrderType.LIST)
            orders = lists[maker];
        else
            orders = bids[maker];
        for (uint i = 0; i < orders.length; i++) {
            if (tokenId == orders[i].tokenId) {
                orders[i] = orders[orders.length - 1];
                orders.pop();
                return true;
            }
        }
        return false;
    }
}
