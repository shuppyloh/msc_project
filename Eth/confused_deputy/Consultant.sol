pragma solidity ^0.4.11;
//interface Inbox that Consultant requires for the save function 
interface Inbox{
    function save(bytes32 data1, bytes32 data2);
}

contract Customer is Inbox{
    bytes32 consultant;
    bytes32 product;
    function Customer(){}
    //the save function is public and accessible by everyone
    function save(bytes32 _consultant, bytes32 _product){ consultant = _consultant; product = _product; }
}

contract Bill is Inbox{
    address owner;
    bytes32 customer; 
    bytes32 bill;
    modifier ownerOnly(){ require(msg.sender == owner);_;}
    function Bill(){ owner = msg.sender; }
    //the save function call can only be triggered by the owner - see the modifier ownerOnly
    function save(bytes32 _customer, bytes32 _bill) ownerOnly { customer = _customer; bill = _bill;} 
}

contract Consultant{
    address owner;
    address myBill;
    function Consultant(address _bill) {
        owner = msg.sender;
        myBill = _bill;
    }
    function hire(address _customerInbox) payable {
        //the consultant bills the customer in a separate contract
        Inbox(myBill).save(bytes32(msg.sender), bytes32(msg.value));
        //then delivers the work into the customer ...
        Inbox(_customerInbox).save(bytes32(address(this)), bytes32("Work done for you"));
        //confused deputy problem arises when a customer passes the address of myBill as _customerInbox
        //even though the customer cannot call save on myBill, this is done through the confused deputy (Consultancy)
        //the consultant overwrites his bill with the work intended for the customer
    }
}
