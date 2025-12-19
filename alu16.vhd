library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu16 is
  port (
    A     : in  std_logic_vector(15 downto 0);
    B     : in  std_logic_vector(15 downto 0);
    SHAMT : in  std_logic_vector(3 downto 0);
    OP    : in  std_logic_vector(4 downto 0);

    Y     : out std_logic_vector(15 downto 0);
    Z     : out std_logic;
    N     : out std_logic;
    C     : out std_logic;
    V     : out std_logic;

    EQ    : out std_logic;
    LT    : out std_logic;
    GE    : out std_logic
  );
end entity;

architecture rtl of alu16 is
  -- Convenient typed views
  signal Au  : unsigned(15 downto 0);
  signal Bu  : unsigned(15 downto 0);
  signal As  : signed(15 downto 0);
  signal Bs  : signed(15 downto 0);

  -- Internal result/flags
  signal y_u : unsigned(15 downto 0);
  signal c_i : std_logic;
  signal v_i : std_logic;
begin
  Au <= unsigned(A);
  Bu <= unsigned(B);
  As <= signed(A);
  Bs <= signed(B);

  -- Comparators are always valid (independent of OP)
  EQ <= '1' when (A = B) else '0';
  LT <= '1' when (As < Bs) else '0';
  GE <= '1' when (As >= Bs) else '0';

  process(Au, Bu, As, Bs, SHAMT, OP)
    variable sh  : natural range 0 to 15;
    variable sum : unsigned(16 downto 0);
    variable dif : unsigned(16 downto 0);
    variable prod: unsigned(31 downto 0);
    variable yv  : unsigned(15 downto 0);
    variable cv  : std_logic;
    variable vv  : std_logic;
  begin
    sh := to_integer(unsigned(SHAMT));

    yv := (others => '0');
    cv := '0';
    vv := '0';

    case OP is
      when "00000" =>  -- PASS_A (MV)
        yv := Au;

      when "00001" =>  -- ADD
        sum := ('0' & Au) + ('0' & Bu);
        yv  := sum(15 downto 0);
        cv  := sum(16);
        -- signed overflow: if A and B same sign, and result different sign
        vv  := (A(15) = B(15)) and (std_logic(yv(15)) /= A(15));

      when "00010" =>  -- SUB
        dif := ('0' & Au) - ('0' & Bu);
        yv  := dif(15 downto 0);
        cv  := dif(16); -- 1 = no borrow (carry-out in unsigned subtract)
        -- signed overflow for subtraction: if A and B different sign and result differs from A sign
        vv  := (A(15) /= B(15)) and (std_logic(yv(15)) /= A(15));

      when "00011" =>  -- AND
        yv := Au and Bu;

      when "00100" =>  -- OR
        yv := Au or Bu;

      when "00101" =>  -- XOR
        yv := Au xor Bu;

      when "00110" =>  -- SHL
        yv := shift_left(Au, sh);

      when "00111" =>  -- SHR (logical)
        yv := shift_right(Au, sh);

      when "01000" =>  -- SAR (arithmetic)
        yv := unsigned(shift_right(As, sh));

      when "01001" =>  -- MUL (low 16)
        prod := Au * Bu;
        yv   := prod(15 downto 0);

      when "01010" =>  -- MULH (high 16) (optional)
        prod := Au * Bu;
        yv   := prod(31 downto 16);

      when others =>
        yv := (others => '0');
    end case;

    y_u <= yv;
    c_i <= cv;
    v_i <= vv;
  end process;

  Y <= std_logic_vector(y_u);

  -- Common flags derived from Y
  Z <= '1' when (y_u = 0) else '0';
  N <= std_logic(y_u(15));
  C <= c_i;
  V <= v_i;

end architecture;
