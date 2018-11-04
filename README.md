# Chord Protocol Implementation
## Group Memebers
* Sandesh Joshi - 4419-5831
* Susmitha Are - 3655-4439
## Implementation
The key space for our chord network is 2^m. We created numNodes number of peers with 2^m keys. Both the node_id's and key_id's are mapped to same key space. We implemented a application that associates a key with a string and implements a distributed hashmap. Next, we caluclated the successor, predecessor of every node. Further we created finger table with m entries for every node. 
Once the peer to peer network is created, the number of nodes that are being contacted to find a successor in N node network is O(logN). In our lookup(key) operation on node N, it checks if the given key's successor is node N. If not it will check the finger table for the closest predecessor Id and forwards the query to it. 
### What is working?
The average number of hops are always O(logN)
For Example: When numNodes = 1000, numRequests =20 then Average hops = 4.9
             When numNodes = 10000, numRequests =20 then Average hops = 6.5
             When numNodes = 20000, numRequests =20 then Average hops = 6.9
             When numNodes = 60000, numRequests =20 then Average hops = 7.8
             When numNodes = 80000, numRequests =20 then Average hops = 8.1
### Largest network 
We are able to create and query peer to peer network with 50,000 nodes. 
### Compliation and Running
Compile the program using "mix escript.build"

Running for Windows:
Run the program using "escript proj3 numNodes numRequests". 
For example: escript proj3 5000 20

Running for Linux and Mac:
Run the program using "./proj3 numNodes numRequests". 
For example: ./proj3 5000 20