# Large Comparators

![Large Comparators Pipelined Efficiently by Recursion](./media/Recursive_Structure.png?raw=true "Large Comparators Pipelined Efficiently by Recursion")

Recursive structures in hardware description languages were not new when I first created this solution prior to 2004. This problem amused me because I wanted to create a structure in VHDL that Synplify Pro could not improve on to know that I had created something optimal. A simple example would be a recursive RAM, consuming a number of bits of address space with each level of recursion. But the point of recursion is to pipeline logic at each level to achieve a required clock speed. The example I have played with here is an _n_-bit comparator.

Please read the blog post [Large Comparators Pipelined Efficiently by Recursion](http://blog.abbey1.org.uk/index.php/technology/large-comparator-pipelined-efficiently-by-recursion) to explain how the code works in detail.
