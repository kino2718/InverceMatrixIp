library ieee;
use ieee.std_logic_1164.all;

entity tb_DivCell is
end tb_DivCell;

architecture SIM of tb_DivCell is
  component DivCell_wrapper
    port (
      aclk : in std_logic;
      aresetn : in std_logic;

      s_axis_dividend_init_tvalid : in std_logic;
      s_axis_dividend_init_tready : out std_logic;
      s_axis_dividend_init_tdata : in std_logic_vector (15 downto 0);
      
      s_axis_dividend_tvalid : in std_logic;
      s_axis_dividend_tready : out std_logic;
      s_axis_dividend_tlast : in std_logic;
      s_axis_dividend_tdata : in std_logic_vector (15 downto 0);
      
      s_axis_divisor_tvalid : in std_logic;
      s_axis_divisor_tready : out std_logic;
      s_axis_divisor_tdata : in std_logic_vector (15 downto 0);

      m_axis_result_tvalid : out std_logic_vector (0 to 0);
      m_axis_result_tready : in std_logic_vector (0 to 0);
      m_axis_result_tlast : out std_logic_vector(0 to 0);
      m_axis_result_tdata : out std_logic_vector (15 downto 0);
      
      m_axis_to_right_tvalid : out std_logic_vector (0 to 0);
      m_axis_to_right_tready : in std_logic_vector (0 to 0);
      m_axis_to_right_tlast : out std_logic_vector(0 to 0);
      m_axis_to_right_tdata : out std_logic_vector (15 downto 0)
      );
  end component;

  component AXISSimMaster
    generic (
      NBITS : natural := 16;
      PACKET_LEN : natural := 4;
      FNAME : string := "input.txt";
      PATTERN : character := 'p'; -- 'p':periodic, 'r':random
      PERIOD : positive := 4;
      INIT_RAND : std_logic_vector(7 downto 1) := "1010011";
      DELAY : time := 1 ns
      );
    port (
      aclk : in std_logic;
      aresetn : in std_logic;
      m_axis_tvalid : out std_logic;
      m_axis_tready : in std_logic;
      m_axis_tlast : out std_logic;
      m_axis_tdata : out std_logic_vector(NBITS-1 downto 0);
      done : out boolean := false
      );
  end component;

  component AXISSimSlave
    generic (
      NBITS : natural := 16;
      FNAME : string := "output.txt";
      PATTERN : character := 'p';
      PERIOD : positive := 4;
      INIT_RAND : std_logic_vector(7 downto 1) := "0101100";
      DELAY : time := 1ns
      );
    port (
      aclk : in std_logic;
      aresetn : in std_logic;
      s_axis_tvalid : in std_logic;
      s_axis_tready : out std_logic;
      s_axis_tlast : in std_logic;
      s_axis_tdata : in std_logic_vector(NBITS-1 downto 0)
      );
  end component;

  constant CYCLE : time := 10 ns; -- 100MHz
  constant HALF_CYCLE : time := 5 ns;
  constant DELAY : time := 1ns;

  signal aclk : std_logic;
  signal aresetn : std_logic;
  
  signal s_axis_dividend_init_tvalid : std_logic;
  signal s_axis_dividend_init_tready : std_logic;
  signal s_axis_dividend_init_tdata : std_logic_vector(15 downto 0);
  
  signal s_axis_dividend_tvalid : std_logic;
  signal s_axis_dividend_tready : std_logic;
  signal s_axis_dividend_tlast : std_logic;
  signal s_axis_dividend_tdata : std_logic_vector(15 downto 0);
  
  signal s_axis_divisor_tvalid : std_logic;
  signal s_axis_divisor_tready : std_logic;
  signal s_axis_divisor_tdata : std_logic_vector(15 downto 0);

  signal m_axis_result_tvalid : std_logic;
  signal m_axis_result_tready : std_logic;
  signal m_axis_result_tlast : std_logic;
  signal m_axis_result_tdata : std_logic_vector(15 downto 0);
  
  signal m_axis_to_right_tdata : std_logic_vector(15 downto 0);
  signal m_axis_to_right_tready : std_logic;
  signal m_axis_to_right_tlast : std_logic;
  signal m_axis_to_right_tvalid : std_logic;

  signal done : boolean;
  
  -- クロックの立ち上がりエッジを待つ
  procedure wait_clock(constant count: in natural:=1) is
  begin
    for i in 1 to count loop
      wait until rising_edge(aclk);
    end loop;
  end procedure;
begin
  -- クロック作成
  process
  begin
    aclk <= '1'; wait for HALF_CYCLE;
    aclk <= '0'; wait for HALF_CYCLE;
  end process;

  -- リセット作成
  process
  begin
    aresetn <= '0';
    wait for DELAY;
    wait_clock(2); -- divider requires reset at least 2 clock cycles
    wait for DELAY;
    aresetn <= '1';
    wait;
  end process;

  -- シミュレーション停止用
  process
  begin
    wait until done;
    wait for CYCLE * 60;
    -- 終了
    assert false
      severity failure;
  end process;

  UDivCell_wrapper : DivCell_wrapper
    port map (
      aclk => aclk,
      aresetn => aresetn,
      s_axis_dividend_init_tvalid => s_axis_dividend_init_tvalid,
      s_axis_dividend_init_tready => s_axis_dividend_init_tready,
      s_axis_dividend_init_tdata => s_axis_dividend_init_tdata,
      s_axis_dividend_tvalid => s_axis_dividend_tvalid,
      s_axis_dividend_tready => s_axis_dividend_tready,
      s_axis_dividend_tlast => s_axis_dividend_tlast,
      s_axis_dividend_tdata => s_axis_dividend_tdata,
      s_axis_divisor_tvalid => s_axis_divisor_tvalid,
      s_axis_divisor_tready => s_axis_divisor_tready,
      s_axis_divisor_tdata => s_axis_divisor_tdata,
      m_axis_result_tvalid(0) => m_axis_result_tvalid,
      m_axis_result_tready(0) => m_axis_result_tready,
      m_axis_result_tlast(0) => m_axis_result_tlast,
      m_axis_result_tdata => m_axis_result_tdata,
      m_axis_to_right_tdata => m_axis_to_right_tdata,
      m_axis_to_right_tready(0) => m_axis_to_right_tready,
      m_axis_to_right_tlast(0) => m_axis_to_right_tlast,
      m_axis_to_right_tvalid(0) => m_axis_to_right_tvalid
      );

  UAXISSimMaster0 : AXISSimMaster
    generic map (
      NBITS => 16,
      PACKET_LEN => 4,
      FNAME => "dividend_init.txt",
      PATTERN => 'r',
      PERIOD => 13
      )
    port map (
      aclk => aclk,
      aresetn => aresetn,
      m_axis_tvalid => s_axis_dividend_init_tvalid,
      m_axis_tready => s_axis_dividend_init_tready,
      m_axis_tlast => open,
      m_axis_tdata => s_axis_dividend_init_tdata,
      done => open
      );

  UAXISSimMaster1 : AXISSimMaster
    generic map (
      NBITS => 16,
      PACKET_LEN => 1,
      FNAME => "dividend.txt",
      PATTERN => 'r',
      INIT_RAND => "0101010",
      PERIOD => 11
      )
    port map (
      aclk => aclk,
      aresetn => aresetn,
      m_axis_tvalid => s_axis_dividend_tvalid,
      m_axis_tready => s_axis_dividend_tready,
      m_axis_tlast => s_axis_dividend_tlast,
      m_axis_tdata => s_axis_dividend_tdata,
      done => done
      );

  UAXISSimMaster2 : AXISSimMaster
    generic map (
      NBITS => 16,
      PACKET_LEN => 4,
      FNAME => "divisor.txt",
      PATTERN => 'r',
      INIT_RAND => "0100010",
      PERIOD => 7
      )
    port map (
      aclk => aclk,
      aresetn => aresetn,
      m_axis_tvalid => s_axis_divisor_tvalid,
      m_axis_tready => s_axis_divisor_tready,
      m_axis_tlast => open,
      m_axis_tdata => s_axis_divisor_tdata,
      done => open
      );

  UAXISSimSlave0 : AXISSimSlave
    generic map (
      NBITS => 16,
      FNAME => "result.txt",
      PATTERN => 'r',
      INIT_RAND => "1100010",
      PERIOD => 5)
    port map (
      aclk => aclk,
      aresetn => aresetn,
      s_axis_tvalid => m_axis_result_tvalid,
      s_axis_tready => m_axis_result_tready,
      s_axis_tlast => m_axis_result_tlast,
      s_axis_tdata => m_axis_result_tdata);

  UAXISSimSlave1 : AXISSimSlave
    generic map (
      NBITS => 16,
      FNAME => "nextcell.txt",
      PATTERN => 'r',
      INIT_RAND => "1100011",
      PERIOD => 3)
    port map (
      aclk => aclk,
      aresetn => aresetn,
      s_axis_tvalid => m_axis_to_right_tvalid,
      s_axis_tready => m_axis_to_right_tready,
      s_axis_tlast => m_axis_to_right_tlast,
      s_axis_tdata => m_axis_to_right_tdata);
end SIM;
