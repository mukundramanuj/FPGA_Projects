	component niosv is
		port (
			clk_clk : in std_logic := 'X'  -- clk
		);
	end component niosv;

	u0 : component niosv
		port map (
			clk_clk => CONNECTED_TO_clk_clk  -- clk.clk
		);

