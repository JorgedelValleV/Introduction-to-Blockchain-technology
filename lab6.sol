// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract lab6ex1 {
    uint[] arr;
    uint sum;
    function generate(uint n) external {
        for (uint i = 0; i < n; i++) {
            arr.push(i*i);
        }
    }
    function computeSum() external {
        sum = 0;
        for (uint i = 0; i < arr.length; i++) {
            sum = sum + arr[i];
        }
    }
}
 
contract lab6ex4 {
    uint[] arr;
    uint sum;
    function generate(uint n) external {
        for (uint i = 0; i < n; i++) {
            arr.push(i*i);
        }
    }
    function computeSum() external {
        uint [] memory c = arr ;
        uint aux = 0;
        uint l = arr . length ;
        for ( uint i = 0; i < l ; i ++) {
            aux = aux + c [ i ];
        }
        sum = aux ;
    }
}

contract lab6ex5 {
    function maxMinMemory(uint[] memory arr) public pure returns (uint maxmin) {
        assembly {
            function fmaxmin (slot) -> maxVal, minVal{
                let len := mload(slot)
                let data := add(slot, 0x20)
                maxVal := mload(data)
                minVal := maxVal
                let i := 1
                for {} lt(i,len) {i:= add(i,1)}
                {
                    let elem := mload(add(data,mul(i,0x20)))
                    if gt(elem,maxVal) { maxVal := elem }
                    if lt(elem,minVal) { minVal := elem }
                }
            }
            let resultmax,resultmin := fmaxmin(arr)
            maxmin:=sub(resultmax,resultmin)
        }
    }
}
contract lab6ex6 {
    uint[] public arr;
    function generate(uint n) external {
        // Populates the array with some weird small numbers.
        bytes32 b = keccak256("seed");
        for (uint i = 0; i < n; i++) {
            uint8 number = uint8(b[i % 32]);
            arr.push(number);
        }
    }
    function maxMinStorage() public view returns (uint maxmin){
        assembly {
            function fmaxmin (slot) -> maxVal, minVal{
                let len := sload(slot)
                mstore(0x0,slot)
                let data:=keccak256(0x0, 0x20)
                maxVal := sload(data)
                minVal := maxVal
                let i := 1
                for {} lt(i,len) {i:= add(i,1)}
                {
                    let elem := sload(add(data,i))
                    if gt(elem,maxVal) { maxVal := elem }
                    if lt(elem,minVal) { minVal := elem }
                }
            }
            let resultmax,resultmin := fmaxmin(arr.slot)
            maxmin:=sub(resultmax,resultmin)
        }
    }
}
contract lab6ex7 {
    uint[] public arr;
    function generate(uint n) external {
        // Populates the array with some weird small numbers.
        bytes32 b = keccak256("seed");
        for (uint i = 0; i < n; i++) {
            uint8 number = uint8(b[i % 32]);
            arr.push(number);
        }
    }
    function maxMinStorage() public view returns (uint maxmin){
        uint maxVal=arr[0];
        uint minVal=arr[0];
        for (uint i = 1; i < arr.length; i++) {
            if(maxVal<arr[i]){
                maxVal= arr[i];
            }
            if(minVal>arr[i]){
                minVal= arr[i];
            }
        }
        maxmin=maxVal-minVal;
    }
}