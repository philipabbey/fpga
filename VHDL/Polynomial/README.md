## Polynomial Division Logic

![Bus-width Polynomial Division Logic](./media/polynomial_division.svg?raw=true "Bus-width Polynomial Division Logic")

I've seen several VHDL implementations that seem to obfuscate the beauty and simplicity of the polynomial division modulo 2 calculation with unnecessary code. I present here the essential single line of VHDL that is required to perform the division inside a clocked VHDL process for any polynomial. I then extend this solution to multiple bits of work per clock cycle with a simple extension of the single line such that between the VHDL and the synthesis tool, all the necessary logic for e.g. byte wide data is derived for you without resorting to any tables in standards documentation. This work actually predates 1999 and therefore the age of blogging, but no one else has written up an equally succinct version of this since then hence it is appearing belatedly.

Please read the blog post [Bus-width Polynomial Division Logic](http://blog.abbey1.org.uk/index.php/technology/bus-width-polynomial-division-logic) to explain how the code works in detail.
