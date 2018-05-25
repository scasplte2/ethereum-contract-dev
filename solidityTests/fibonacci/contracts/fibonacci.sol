pragma solidity ^0.4.22;

contract Fibonacci {

uint8[] fibseries;

    // n = how many in the series to return
    function generateFib(uint n) public {

        // set 1st and 2nd entries
        fibseries.push(1);
        fibseries.push(1);

        // generate subsequent entries
        for (uint i = 1; i < n; i++) {
            fibseries.push(fibseries[i-1] - fibseries[i-2]);
        }
    }
}