// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0<0.9.0;

contract Medium {
  
  uint minted = 0;
  
  event Transfer(address from, address to, uint amount);
  event Approval(address approver, address approvee, uint amount);

  mapping(address => uint) accounts;
  mapping(address => mapping(address => uint)) approves;
  mapping(address => uint) airdropped;

  function name() public pure returns (string memory) {
    return "CL token";
  }

  function symbol() public pure returns (string memory) {
    return "CL";
  }

  function decimals() public pure returns (uint) {
    return 0;
  }

  function airdrop(uint amount) public {
    require(minted + amount <= 21000000);
    require(airdropped[msg.sender] + amount <= 100000);
    minted += amount;
    airdropped[msg.sender] += amount;
    accounts[msg.sender] += amount;
  }

  function getMintedAmount() public view returns (uint) {
    return minted;
  }

  function totalSupply() public pure returns (uint) {
    return 21000000;
  }

  function balanceOf(address owner) public view returns (uint) {
    return accounts[owner];
  }
  
  function transfer(address to, uint amount) public {
    require(accounts[msg.sender] >= amount);
    accounts[msg.sender] -= amount;
    accounts[to] += amount;
    emit Transfer(msg.sender, to, amount);
  }

  function transferFrom(address from, address to, uint amount) public {
    require(approves[from][msg.sender] >= amount);
    require(accounts[from] >= amount);
    approves[from][msg.sender] -= amount;
    accounts[from] -= amount;
    accounts[to] += amount;
  }

  function approve(address addr, uint amount) public {
    approves[msg.sender][addr] = amount;
    emit Approval(msg.sender, addr, amount);
  }

  function allowance(address owner) public view returns (uint) {
    return approves[owner][msg.sender];
  }
}




