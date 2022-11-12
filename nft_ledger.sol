// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./nft_market.sol";

contract NFTLedger {

  event Transferrd(address owner, address to, uint256 tokenId);
  event TransferredFrom(address owner, address agent, address to, uint256 tokenId);
  event ApproveDone(address owner, address approvee, uint256 tokenId);
  event ApproveCancelled(address owner, address approvee, uint256 tokenId);
  event ApproveAllDone(address owner, address operator);
  event ApproveAllCancelled(address owner, address operator);

  NFTMarket market;

  uint256 token_counter = 0;

  mapping(uint256 => address) owners;
  mapping(address => mapping(uint256 => address[])) approvees;
  mapping(address => address[]) operators;

  function has_address(address[] storage set, address addr) internal view returns (bool, uint) {
    for (uint i = 0; i < set.length; i++)
      if (addr == set[i])
        return (true, i);
    return (false, 0);
  }

  function setMarket(address addr) public {
    market = NFTMarket(addr);
  }

  function mint() public {
    owners[token_counter++] = msg.sender;
  }

  function getOwner(uint256 tokenId) public view returns (address) {
    return owners[tokenId];
  }

  function transfer(uint256 tokenId, address to) public {
    require(owners[tokenId] == msg.sender, "You are not the owner of this token.");
    require(to != msg.sender, "Attempt to transfer token to the owner.");
    delete approvees[msg.sender][tokenId];
    owners[tokenId] = to;
    market.ownership_altered(msg.sender, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public {
    require(owners[tokenId] == from, "Address does not have this token.");
    require(from != to, "Attempt to transfer token to the owner.");
    (bool is_approvee, ) = has_address(approvees[from][tokenId], msg.sender);
    (bool is_operator, ) = has_address(operators[from], msg.sender);
    if (!is_approvee && !is_operator)
      revert("You are not approved to transfer this token.");
    delete approvees[from][tokenId];
    owners[tokenId] = to;
    market.ownership_altered(from, tokenId);
  }

  function approve(uint256 tokenId, address to, bool flag) public {
    require(owners[tokenId] == msg.sender, "You are not the owner of this token.");
    address[] storage approvee_set = approvees[msg.sender][tokenId];
    (bool has, uint index) = has_address(approvee_set, to);
    if (flag) {
      if (!has) {
        approvee_set.push(to);
        emit ApproveDone(msg.sender, to, tokenId);
      } else {
        revert("Address already approved.");
      }
    } else {
      if (has) {
        approvee_set[index] = approvee_set[approvee_set.length - 1];
        approvee_set.pop();
        emit ApproveCancelled(msg.sender, to, tokenId);
      } else {
        revert("Removing approvee that does not exist.");
      }
    }
  }

  function approveAll(address to, bool flag) public {
    address[] storage operator_set = operators[msg.sender];
    (bool has, uint index) = has_address(operator_set, to);
    if (flag) {
      if (!has) {
        operator_set.push(to);
        emit ApproveAllDone(msg.sender, to);
      } else {
        revert("Address already approved all.");
      }
    } else {
      if (has) {
        operator_set[index] = operator_set[operator_set.length - 1];
        operator_set.pop();
        emit ApproveAllCancelled(msg.sender, to);
      } else {
        revert("Removing operator that does not exist.");
      }
    }
  }
}
