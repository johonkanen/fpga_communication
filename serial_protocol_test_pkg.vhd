
LIBRARY ieee  ; 
    USE ieee.std_logic_1164.all  ; 
    USE ieee.numeric_std.all  ; 

    use work.uart_protocol_pkg.all;

package uart_protocol_test_pkg is

    function write_frame (
        address : natural;
        data : std_logic_vector(15 downto 0))
    return base_array;

    function read_frame ( address : natural)
        return base_array;

    function stream_frame (
        address : natural
        ; stream_length : natural)
    return base_array;

    function stream_frame ( address : natural)
        return base_array;

end package uart_protocol_test_pkg;

package body uart_protocol_test_pkg is

    function write_frame
    (
        address : natural;
        data : std_logic_vector(15 downto 0)
    )
    return base_array
    is
        variable retval : base_array(0 to 4);
    begin
        retval(0) := std_logic_vector'(x"04");
        retval(1 to 2) := int_to_bytes(address);
        retval(3 to 4) := (data(15 downto 8), data(7 downto 0));

        return retval;
    end write_frame;

    function read_frame
    (
        address : natural
    )
    return base_array
    is
        variable retval : base_array(0 to 2);
    begin
        retval(0) := std_logic_vector'(x"02");
        retval(1 to 2) := int_to_bytes(address);

        return retval;
    end read_frame;

    function stream_frame
    (
        address : natural
        ; stream_length : natural
    )
    return base_array
    is
        variable retval : base_array(0 to 5);
        variable std_length : std_logic_vector(23 downto 0) := std_logic_vector(to_unsigned(stream_length, 24));
    begin
        retval(0) := std_logic_vector'(x"05");
        retval(1 to 2) := int_to_bytes(address);
        retval(3 to 5) := (3 => std_length(23 downto 16)
                        , 4 => std_length(15 downto 8)
                        , 5 =>std_length(7 downto 0)
                        );

        return retval;
    end stream_frame;

    function stream_frame
    (
        address : natural
    )
    return base_array
    is
    begin
        return stream_frame(address, 1);
    end stream_frame;

end package body;

