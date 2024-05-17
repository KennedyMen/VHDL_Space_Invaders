library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- btn connected to up/down pushbuttons for now but
-- eventually will get data from UART
entity pong_graph_st is
    port(
        clk, reset: in std_logic;
        btn: in std_logic_vector(4 downto 0);--- updated bits to 5
        video_on: in std_logic;
        hit_cnt: out std_logic_vector (2 downto 0);
        kill_cnt:out std_logic_vector (2 downto 0);
        pixel_x, pixel_y: in std_logic_vector(9 downto 0);
        graph_rgb: out std_logic_vector(2 downto 0)
    );
end pong_graph_st;

architecture sq_ball_arch of pong_graph_st is
-- Signal used to control speed of ball and how

-- often pushbuttons are checked for paddle movement.
    signal refr_tick: std_logic;
    signal pix_x, pix_y: unsigned(9 downto 0);




    constant MAX_X: integer := 640;
    constant MAX_Y: integer := 480;

-- wall left and right boundary of wall (full height)
    constant WALL_X_L: integer := 32;
    constant WALL_X_R: integer := 35;

-- paddle left, right, top, bottom and height left &
-- right are constant. top & bottom are signals to
-- allow movement. bar_y_t driven by reg below.

    --constant BAR_X_L: integer:=600;
    --constant BAR_X_R: integer := 603;

    signal bar_x_l, bar_x_r: unsigned(9 downto 0);
    signal bar_y_t, bar_y_b: unsigned(9 downto 0);

    constant BAR_Y_SIZE: integer := 32;
    constant BAR_X_SIZE: integer :=32; ---new

-- reg to track top boundary
    signal bar_y_reg, bar_y_next: unsigned(9 downto 0);
    signal bar_x_reg, bar_x_next: unsigned(9 downto 0);----new


    signal bool_l, bool_r: std_logic;
    signal bool_lr: std_logic_vector(1 downto 0);
-- bar moving velocity when a button is pressed
-- the amount the bar is moved.

    constant BAR_V: integer:= 4;
    constant BAR_H: integer:= 2;

--  First asteriod  -- asteriod left, right, top and bottom
-- all vary. Left and top driven by registers below.
    constant R_ONE_SIZE: integer := 8;
    signal RONE_x_l, RONE_x_r: unsigned(9 downto 0);
    signal RONE_y_t, RONE_y_b: unsigned(9 downto 0);



    --- reg to track left and top boundary
    signal RONE_x_reg, RONE_x_next: unsigned(9 downto 0);
    signal RONE_y_reg, RONE_y_next: unsigned(9 downto 0);

    --- Second Asteriod
    -------------------------------------------------------------------------
    constant R_TW0_SIZE: integer := 8;
    signal RTwo_x_l, RTwo_x_r: unsigned(9 downto 0);
    signal RTwo_y_t, RTwo_y_b: unsigned(9 downto 0);


    --- reg to track left and top boundary
    signal RTwo_x_reg, RTwo_x_next: unsigned(9 downto 0);
    signal RTwo_y_reg, RTwo_y_next: unsigned(9 downto 0);


    ---- Third Asteriod
    -------------------------------------------------------------------------
    constant R_THREE_SIZE: integer := 8;
    signal RThree_x_l, RThree_x_r: unsigned(9 downto 0);
    signal RThree_y_t, RThree_y_b: unsigned(9 downto 0);


    --- reg to track left and top boundary
    signal RThree_x_reg, RThree_x_next: unsigned(9 downto 0);
    signal RThree_y_reg, RThree_y_next: unsigned(9 downto 0);



    ------------------------------------------------------------------------------------
    -- reg to track aestoroids speeds
    signal x_RONE_delta_reg, x_RONE_delta_next: unsigned(9 downto 0);
    signal y_RONE_delta_reg, y_RONE_delta_next: unsigned(9 downto 0);

    signal x_RTwo_delta_reg, x_RTwo_delta_next: unsigned(9 downto 0);
    signal y_RTwo_delta_reg, y_RTwo_delta_next: unsigned(9 downto 0);

    signal x_RThree_delta_reg, x_RThree_delta_next: unsigned(9 downto 0);
    signal y_RThree_delta_reg, y_RThree_delta_next: unsigned(9 downto 0);


    -- R movement One can be pos or neg
    constant RONE_V_P: unsigned(9 downto 0):= to_unsigned(5,10);
    constant RONE_V_N: unsigned(9 downto 0):= unsigned(to_signed(-4,10));



    -- R movement Two can be pos or neg
    constant RTwo_V_P: unsigned(9 downto 0):= to_unsigned(6,10);
    constant RTwo_V_N: unsigned(9 downto 0):= unsigned(to_signed(-6,10));

    -- R movement Three can be pos or neg
    constant RThree_V_P: unsigned(9 downto 0):= to_unsigned(3,10);
    constant RThree_V_N: unsigned(9 downto 0):= unsigned(to_signed(-3,10));






    ------------------------------FIRING BALL---------------------------------------------------------------------------------
    constant FIRING_SIZE: integer := 20;
    signal firing_ball_x_l, firing_ball_x_r: unsigned(9 downto 0);
    signal firing_ball_y_t, firing_ball_y_b: unsigned(9 downto 0);
    signal firing_ball_x_reg, firing_ball_y_reg: unsigned(9 downto 0);
    signal firing_ball_y_next , firing_ball_x_next: unsigned(9 downto 0);
    signal x_delta_firing_reg, x_delta_firing_next: unsigned(9 downto 0);
    signal y_delta_firing_reg, y_delta_firing_next: unsigned(9 downto 0);
    constant FIRING_BALL_V_P: unsigned(9 downto 0):= to_unsigned(2,10);




------------------------------------------------- ROMS -----------------------------------------------------------------------------------------
    type asteriodOne_rom_type is array(0 to 7) of std_logic_vector(0 to 7);
    constant ASTERIODONE_ROM: asteriodOne_rom_type:= (
        "00000001",
        "01111110",
        "11111111",
        "11110111",
        "11111111",
        "11111111",
        "11111110",
        "11111100");


    signal RONE_rom_addr, RONE_rom_col: unsigned(2 downto 0);
    signal RONE_rom_data: std_logic_vector(7 downto 0);
    signal RONE_rom_bit: std_logic;



-- round asteriod  Two image
    type asteriodTwo_rom_type is array(0 to 7) of std_logic_vector(0 to 7);
    constant RTWO_ROM: asteriodTwo_rom_type:= (
        "00000000",
        "01111110",
        "11111110",
        "11111111",
        "11100111",
        "11111111",
        "01111110",
        "00111100");


    signal RTwo_rom_addr, RTwo_rom_col: unsigned(2 downto 0);
    signal RTwo_rom_data: std_logic_vector(7 downto 0);
    signal RTwo_rom_bit: std_logic;



-- round asteriod  Three image
    type asteriodThree_rom_type is array(0 to 7) of std_logic_vector(0 to 7);
    constant RTHREE_ROM: asteriodThree_rom_type:= (
        "00111100",
        "01111110",
        "11111111",
        "11100011",
        "11111111",
        "11111111",
        "01111100",
        "01111100");


    signal RThree_rom_addr, RThree_rom_col: unsigned(2 downto 0);
    signal RThree_rom_data: std_logic_vector(7 downto 0);
    signal RThree_rom_bit: std_logic;
    type firing_rom_type is array(0 to 15) of std_logic_vector(0 to 15);
    constant FIRING_ROM: firing_rom_type := (
        "0000111111110000",
        "0001111111111000",
        "0011111111111100",
        "0111000000001110",
        "0000011111100000",
        "0000111111110000",
        "0000111111110000",
        "0000111111110000",
        "0000111111110000",
        "0000111111110000",
        "0000111111110000",
        "0000111111110000",
        "0000111111110000",
        "0000111111110000",
        "0000111111110000",
        "0000111111110000"

    );
    signal firing_rom_addr, firing_rom_col: unsigned(3 downto 0);
    signal firing_rom_data: std_logic_vector(15 downto 0);
    signal firing_rom_bit: std_logic;
    type SHIP_rom_type is array(0 to 10) of std_logic_vector(0 to 10);
    constant SHIP_ROM: SHIP_rom_type := (
        "0000000000",
        "0000110000",
        "0001111000",
        "1111111111",
        "1111111111",
        "1111111111",
        "1111111111",
        "1100000011",
        "1100000011",
        "1100000011",
        "1100000011"

    );
    signal SHIP_rom_addr, SHIP_rom_col: unsigned(3 downto 0);
    signal SHIP_rom_data: std_logic_vector(10 downto 0);
    signal SHIP_rom_bit: std_logic;

    signal ZERO: unsigned(9 downto 0);








--------------------------ON or OFF VALUES--------------------------------------------------------------------------------
    signal wall_on, bar_on : std_logic;
    signal sq_RONE_on, sq_RTwo_on, sq_RThree_on : std_logic;
    signal rd_RONE_on, rd_RTwo_on, rd_RThree_on : std_logic;
    signal sq_firing_ball_on, rd_firing_ball_on: std_logic; --- new firing ball image
    signal rd_bar_on:std_logic;
    signal wall_rgb, bar_rgb : std_logic_vector(2 downto 0);
    signal hit_cnt_reg, hit_cnt_next,kill_cnt_reg, kill_cnt_next: unsigned (2 downto 0);
    signal RONE_rgb, RTwo_rgb, RThree_rgb, firing_ball_rgb: std_logic_vector(2 downto 0);

-- ====================================================
begin
    process (clk, reset)
    begin
        if (reset = '1') then
            bar_y_reg <= (others => '0');
            bar_x_reg <=(others => '0');---new
            hit_cnt_reg<=(others => '0');
            kill_cnt_reg<=(others => '0');

            RONE_x_reg <= (others => '0');
            RONE_y_reg <= (others => '0');
            RTwo_x_reg <= (others => '0');
            RTwo_y_reg <= (others => '0');
            RThree_x_reg <= (others => '0');
            RThree_y_reg <= (others => '0');


            x_RONE_delta_reg <= ("0000000100");
            y_RONE_delta_reg <= ("0000000100");

            x_RTwo_delta_reg <= ("0000000100");
            y_RTwo_delta_reg <= ("0000000100");

            x_RThree_delta_reg <= ("0000000100");
            y_RThree_delta_reg <= ("0000000100");


            firing_ball_x_reg <=(others => '0');--new initialization
            firing_ball_y_reg <=(others => '0');--new  inititialization


        elsif (clk'event and clk = '1') then
            bar_y_reg <= bar_y_next;
            bar_x_reg <= bar_x_next;-- new

            RONE_x_reg <= RONE_x_next;
            RONE_y_reg <= RONE_y_next;

            RTwo_x_reg <= RTwo_x_next;
            RTwo_y_reg <= RTwo_y_next;

            RThree_x_reg <= RThree_x_next;
            RThree_y_reg <= RThree_y_next;

            hit_cnt_reg<= hit_cnt_next;
            kill_cnt_reg<= kill_cnt_next;




            x_RONE_delta_reg <= x_RONE_delta_next;
            y_RONE_delta_reg <= y_RONE_delta_next;


            x_RTwo_delta_reg <= x_RTwo_delta_next;
            y_RTwo_delta_reg <= y_RTwo_delta_next;

            x_RThree_delta_reg <= x_RThree_delta_next;
            y_RThree_delta_reg <= y_RThree_delta_next;


            firing_ball_x_reg <= firing_ball_x_next;---new update  output only when the rising edge of the clock
            firing_ball_y_reg <= firing_ball_y_next;---new

        end if;
    end process;
    Zero <= (others => '0');
    pix_x <= unsigned(pixel_x);
    pix_y <= unsigned(pixel_y);

-- refr_tick: 1-clock tick asserted at start of v_sync,
-- e.g., when the screen is refreshed -- speed is 60 Hz
    refr_tick <= '1' when (pix_y = 481) and (pix_x = 0) else '0';

-- wall left vertical stripe
    wall_on <= '1' when (WALL_X_L <= pix_x) and (pix_x <= WALL_X_R) else '0';
    wall_rgb <= "001"; -- blue

-- pixel within paddle




-- Process bar movement requests ( UP AND DOWN)
    process( bar_y_reg, bar_y_b, bar_y_t, refr_tick, btn)
    begin
        bar_y_next <= bar_y_reg; -- no move
        if ( refr_tick = '1' ) then
-- if btn 1 pressed and paddle not at bottom yet
            if ( btn(1) = '1' and bar_y_b < (MAX_Y - 1 - BAR_V)) then
                bar_y_next <= bar_y_reg + BAR_V;
-- if btn 0 pressed and bar not at top yet
            elsif ( btn(0) = '1' and bar_y_t >  BAR_V) then
                bar_y_next <= bar_y_reg - BAR_V;
            end if;
        end if;
    end process;


--horizontal bar movement
    bool_l <= '1' when (btn(2) = '1') and (bar_x_l > (BAR_H)) else '0';
    bool_r <= '1' when (btn(3) = '1') and (bar_x_r < MAX_X - 1 - BAR_H) else '0';


    bool_lr <= bool_l & bool_r;

    process(bar_x_reg, bar_x_r, bar_x_l, refr_tick, btn)
    begin
        bar_x_next <= bar_x_reg;
        if(refr_tick = '1') then
            case bool_lr is
                when "00" =>
                    bar_x_next <= bar_x_reg;
                when "01" =>
                    bar_x_next <= bar_x_reg + BAR_H;
                when "10" =>
                    bar_x_next <= bar_x_reg - BAR_H;
                when others =>
                    bar_x_next <= bar_x_reg;
            end case;
        end if;
    end process;




---------------------------------COORDINATES--------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
-- set coordinates of  first square  asteriod.
    RONE_x_l <= RONE_x_reg;
    RONE_y_t <= RONE_y_reg;
    RONE_x_r <= RONE_x_l + R_ONE_SIZE - 1;
    RONE_y_b <= RONE_y_t + R_ONE_SIZE - 1;



-- set coordinates of  second square  asteriod.
    RTwo_x_l <= RTwo_x_reg;
    RTwo_y_t <= RTwo_y_reg;
    RTwo_x_r <= RTwo_x_l + R_TW0_SIZE - 1;
    RTwo_y_b <= RTwo_y_t + R_TW0_SIZE - 1;


-- set coordinates of  Third square  asteriod.
    RThree_x_l <= RThree_x_reg;
    RThree_y_t <= RThree_y_reg;
    RThree_x_r <= RThree_x_l + R_THREE_SIZE - 1;
    RThree_y_b <= RThree_y_t + R_THREE_SIZE - 1;





-- set coordinates of firing ball

    firing_ball_x_l <= firing_ball_x_reg;
    firing_ball_y_t <= firing_ball_y_reg;
    firing_ball_x_r <= firing_ball_x_l + FIRING_SIZE - 1;
    firing_ball_y_b <= firing_ball_y_t + FIRING_SIZE - 1;

    -- coordingats of bar/ SHIP
    bar_x_l <= bar_x_reg;
    bar_y_t <= bar_y_reg;
    bar_x_r <= bar_x_l + BAR_X_SIZE - 1;
    bar_y_b <= bar_y_t + BAR_Y_SIZE - 1;
    --------------------------PIXEL WITHIN CODE FOR RGB--------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    -- pixel within  First square ball
    sq_RONE_on <= '1' when (RONE_x_l <= pix_x) and
    (pix_x <= RONE_x_r) and (RONE_y_t <= pix_y) and
    (pix_y <= RONE_y_b) else '0';


-- pixel within  Second square ball
    sq_RTwo_on <= '1' when (RTwo_x_l <= pix_x) and
    (pix_x <= RTwo_x_r) and (RTwo_y_t <= pix_y) and
    (pix_y <= RTwo_y_b) else '0';

-- pixel within  Third square ball
    sq_RThree_on <= '1' when (RThree_x_l <= pix_x) and
    (pix_x <= RThree_x_r) and (RThree_y_t <= pix_y) and
    (pix_y <= RThree_y_b) else '0';






---pixel within firing ball
    sq_firing_ball_on <= '1' when (firing_ball_x_l <= pix_x) and
    (pix_x <= firing_ball_x_r) and (firing_ball_y_t <= pix_y) and
    (pix_y <= firing_ball_y_b) else '0';
--- Pixel withing SHIP-------------------------------------------
    bar_on <= '1' when (bar_x_l <= pix_x) and
    (pix_x <= bar_x_r) and (bar_y_t <= pix_y) and
    (pix_y <= bar_y_b) else '0';
-- map scan coord to ROM addr/col -- use low order three
-- bits of pixel and ball positions.

--------------------------------COLUMN AND ROW CREATION----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------
    RONE_rom_addr <= pix_y(2 downto 0) - RONE_y_t(2 downto 0);
    RONE_rom_col <= pix_x(2 downto 0) - RONE_x_l(2 downto 0);
    RONE_rom_data <= ASTERIODONE_ROM(to_integer(RONE_rom_addr));
    RONE_rom_bit <= RONE_rom_data(to_integer(RONE_rom_col));
    rd_RONE_on <= '1' when (sq_RONE_on = '1') and (RONE_rom_bit = '1') else '0';
    RONE_rgb <= "100"; -- red
    ---------------ASTERIOD TWO---------------------------------------------------------------
    RTwo_rom_addr <= pix_y(2 downto 0) - RTwo_y_t(2 downto 0);
    RTwo_rom_col <= pix_x(2 downto 0) - RTwo_x_l(2 downto 0);
    RTwo_rom_data <= RTWO_ROM(to_integer(RTwo_rom_addr));
    RTwo_rom_bit <= RTwo_rom_data(to_integer(RTwo_rom_col));
    rd_RTwo_on <= '1' when (sq_RTwo_on = '1') and (RTwo_rom_bit = '1') else '0';
    RTwo_rgb <= "010"; -- green
    --------------ASTERIOD THREE-----------------------------------------------------------------
    RThree_rom_addr <= pix_y(2 downto 0) - RThree_y_t(2 downto 0);
    RThree_rom_col <= pix_x(2 downto 0) - RThree_x_l(2 downto 0);
    RThree_rom_data <= RTHREE_ROM(to_integer(RThree_rom_addr));
    RThree_rom_bit <= RThree_rom_data(to_integer(RThree_rom_col));
    rd_RThree_on <= '1' when (sq_RThree_on = '1') and (RThree_rom_bit = '1') else '0';
    RThree_rgb <= "001"; -- blue
    --------------FIRING  BALL---------------------------------------------------------------------
    firing_rom_addr <= pix_y(3 downto 0) - firing_ball_y_t(3 downto 0);
    firing_rom_col <= pix_x(3 downto 0) - firing_ball_x_l(3 downto 0);
    firing_rom_data <= FIRING_ROM(to_integer(firing_rom_addr));
    firing_rom_bit <= firing_rom_data(to_integer(firing_rom_col));
    rd_firing_ball_on <= '1' when (sq_firing_ball_on = '1') and (firing_rom_bit = '1') else '0';
    firing_ball_rgb <= "100";--red
    -------------SHIP-------------------------------------------------------------------------------
    ship_rom_addr <= pix_y(3 downto 0) - bar_y_t(3 downto 0);
    ship_rom_col <= pix_x(3 downto 0) - bar_x_l(3 downto 0);
    ship_rom_data <= ship_ROM(to_integer(ship_rom_addr));
    ship_rom_bit <= ship_rom_data(to_integer(ship_rom_col));
    rd_bar_on <= '1' when (bar_on = '1') and (ship_rom_bit = '1') else '0';
    bar_rgb <= "111";--white


-----------------------POSITIONAL ARGUMENTS AND ADDED
-- Update the first R position 60 times per second.
    RONE_x_next <= RONE_x_reg + x_RONE_delta_reg when
    refr_tick = '1' else RONE_x_reg;
    RONE_y_next <= RONE_y_reg + y_RONE_delta_reg when
    refr_tick = '1' else RONE_y_reg;

-- Update the second R position 60 times per second.
    RTwo_x_next <= RTwo_x_reg + x_RTwo_delta_reg when
    refr_tick = '1' else RONE_x_reg;
    RTwo_y_next <= RTwo_y_reg + y_RTwo_delta_reg when
    refr_tick = '1' else RTwo_y_reg;


-- Update the Third R position 60 times per second.
    RThree_x_next <= RThree_x_reg + x_RThree_delta_reg when
    refr_tick = '1' else RONE_x_reg;
    RThree_y_next <= RThree_y_reg + y_RThree_delta_reg when
    refr_tick = '1' else RThree_y_reg;

-- Set the value of the next ball position according to
-- the boundaries.

    process(x_RONE_delta_reg, y_RONE_delta_reg, RONE_y_t , RONE_y_b, RONE_x_r, RONE_x_l,
            bar_y_t, bar_y_b,bar_x_r , bar_x_l )
    begin
        x_RONE_delta_next <= x_RONE_delta_reg;
        y_RONE_delta_next <= y_RONE_delta_reg;

        --  if First R reached top, make offset positive
        if (RONE_y_t < 1) then
            y_RONE_delta_next <= RONE_V_P;
        -- reached bottom, make negative
        elsif (RONE_y_b > (MAX_Y - 1)) then
            y_RONE_delta_next <= RONE_V_N;
-- reach wall, bounce back
        elsif (RONE_x_l <= WALL_X_R ) then
            x_RONE_delta_next <= RONE_V_P;
-- right corner of ball inside bar
        elsif ((bar_x_l <= RONE_x_r) and (RONE_x_r <= bar_x_r)) then
-- some portion of ball hitting paddle, reverse dir
            if ((bar_y_t <= RONE_y_b) and (RONE_y_t <= bar_y_b)) then
                x_RONE_delta_next <= RONE_V_N;
            end if;
        end if;

    end process;


    process(x_RTwo_delta_reg, y_RTwo_delta_reg, RTwo_y_t, RTwo_y_b, RTwo_x_l, bar_y_t, bar_y_b, RTwo_x_r)
    begin
        x_RTwo_delta_next <= x_RTwo_delta_reg;
        y_RTwo_delta_next <= y_RTwo_delta_reg;

        --  if Second  R reached top, make offset positive
        if (RTwo_y_t < 1) then
            y_RTwo_delta_next <= RTwo_V_P;
        -- reached bottom, make negative
        elsif (RTwo_y_b > (MAX_Y - 1)) then
            y_RTwo_delta_next <= RTwo_V_N;
-- reach wall, bounce back
        elsif (RTwo_x_l <= WALL_X_R) then
            x_RTwo_delta_next <= RTwo_V_P;
-- right corner of ball inside bar
        elsif ((bar_x_l <= RTwo_x_r) and (RTwo_x_r <= bar_x_r)) then
-- some portion of ball hitting paddle, reverse dir
            if ((bar_y_t <= RTwo_y_b) and (RTwo_y_t <= bar_y_b)) then
                x_RTwo_delta_next <= RTwo_V_N;
            end if;
        end if;
    end process;


    process(RThree_y_t, RThree_y_b, RThree_x_r, RThree_x_l, bar_y_t, bar_y_b, y_RThree_delta_reg, bar_x_l, bar_x_r)
    begin
        x_RThree_delta_next <= x_RThree_delta_reg;
        y_RThree_delta_next <= y_RThree_delta_reg;
        --  if Third  R reached top, make offset positive
        if ( RThree_y_t < 1 ) then
            y_RThree_delta_next <= RThree_V_P;
        -- reached bottom, make negative
        elsif (RThree_y_b > (MAX_Y - 1)) then
            y_RThree_delta_next <= RThree_V_N;
-- reach wall, bounce back
        elsif (RThree_x_l <= WALL_X_R ) then
            x_RThree_delta_next <= RThree_V_P;
-- right corner of ball inside bar
        elsif ((bar_x_l <= RThree_x_r) and (RThree_x_r <= bar_x_r)) then
-- some portion of ball hitting paddle, reverse dir
            if ((bar_y_t <= RThree_y_b) and (RThree_y_t <= bar_y_b)) then
                x_RThree_delta_next <= RThree_V_N;
            end if;
        end if;
    end process;


    process (firing_ball_x_reg, firing_ball_y_reg, refr_tick, btn , bar_y_reg, bar_x_reg,  bar_x_l, firing_ball_y_t)
    begin
        --- default values
        firing_ball_x_next<= firing_ball_x_reg;
        firing_ball_y_next <= firing_ball_y_reg;

        if (refr_tick = '1') then
            -- Reset firing ball position if firing button is pressed
            if (btn(4)='1') then
                firing_ball_x_next <= bar_x_l; -- Set firing ball x position to bar position & unisgned
                firing_ball_y_next <= bar_y_reg; -- Set firing ball y position to bar position
            else
                -- Move firing ball vertically
                if (firing_ball_y_t > 0 and  firing_ball_y_reg < MAX_Y )then
                    firing_ball_y_next <= firing_ball_y_reg - RONE_V_P; -- Move UP
                end if;
            end if;
        end if;
    end process;



    process (video_on, wall_on, rd_bar_on, rd_RONE_on, rd_RTwo_on, rd_RThree_on,
            wall_rgb, bar_rgb,RONE_rgb, RTwo_rgb , RThree_rgb , rd_firing_ball_on, firing_ball_rgb )

    begin
        if (video_on = '0') then
            graph_rgb <= "000"; -- blank
        else

            if(rd_firing_ball_on = '1') then
                graph_rgb <= firing_ball_rgb;
            elsif (wall_on = '1') then-- new
                graph_rgb <= wall_rgb;
            elsif (rd_bar_on = '1') then
                graph_rgb <= bar_rgb;
            elsif (rd_RONE_on = '1') then
                graph_rgb <= RONE_rgb;
            elsif (rd_RTwo_on = '1') then
                graph_rgb <= RTwo_rgb;
            elsif (rd_RThree_on = '1') then
                graph_rgb <= RThree_rgb;
            else
                graph_rgb <= "110"; -- yellow bkgnd
            end if;
        end if;

    end process;


    hit_cnt_next <= hit_cnt_reg+1 when (((firing_ball_x_l < RONE_x_r)
            and (firing_ball_y_t < RONE_y_b))and refr_tick = '1') else
    hit_cnt_reg+1 when (((firing_ball_x_r < RONE_x_l) and (firing_ball_y_t < RONE_y_b)and (RONE_y_b < firing_ball_y_t)and (RONE_x_l < firing_ball_x_r))and refr_tick = '1')
    else hit_cnt_reg;


    kill_cnt_next <= kill_cnt_reg+1 when ((BAR_X_L < ROne_x_r)
        and (ROne_x_r < BAR_X_L + ROne_V_P)
        and (x_ROne_delta_reg = ROne_V_N)
        and (bar_y_t < ROne_y_b)
        and (ROne_y_t < bar_y_b)
        and refr_tick = '1')
    else kill_cnt_reg;

    -- output logic
    hit_cnt <= std_logic_vector(hit_cnt_reg);
    kill_cnt<= std_logic_vector(kill_cnt_reg);
    RONE_y_next <= (others=> '0') when(((firing_ball_x_l < RONE_x_r)
            and (firing_ball_y_t < RONE_y_b))and refr_tick = '1') else
    hit_cnt_reg+1 when (((firing_ball_x_r < RONE_x_l) and (firing_ball_y_t < RONE_y_b)and (RONE_y_b < firing_ball_y_t)and (RONE_x_l < firing_ball_x_r))and refr_tick = '1')
    else hit_cnt_reg;
    RTWO_y_next <= (others=> '0') when(((firing_ball_x_l < RTWO_x_r)
            and (firing_ball_y_t < RTWO_y_b))and refr_tick = '1') else
    hit_cnt_reg+1 when (((firing_ball_x_r < RTWO_x_l) and (firing_ball_y_t < RTWO_y_b)and (RTWO_y_b < firing_ball_y_t)and (RTWO_x_l < firing_ball_x_r))and refr_tick = '1')
    else hit_cnt_reg;
    RThree_y_next <= (others=> '0') when(((firing_ball_x_l < RThree_x_r)
            and (firing_ball_y_t < RTHREE_y_b))and refr_tick = '1') else
    hit_cnt_reg+1 when (((firing_ball_x_r < RTHREE_x_l) and (firing_ball_y_t < RTHREE_y_b)and (RTHREE_y_b < firing_ball_y_t)and (RTHREE_x_l < firing_ball_x_r))and refr_tick = '1')
    else hit_cnt_reg;
    RONE_x_next <= (others=> '0') when(((firing_ball_x_l < RONE_x_r)
            and (firing_ball_y_t < RONE_y_b))and refr_tick = '1') else
    hit_cnt_reg+1 when (((firing_ball_x_r < RONE_x_l) and (firing_ball_y_t < RONE_y_b)and (RONE_y_b < firing_ball_y_t)and (RONE_x_l < firing_ball_x_r))and refr_tick = '1')
    else hit_cnt_reg;
    RTWO_x_next <= (others=> '0') when(((firing_ball_x_l < RTWO_x_r)
            and (firing_ball_y_t < RTWO_y_b))and refr_tick = '1') else
    hit_cnt_reg+1 when (((firing_ball_x_r < RTWO_x_l) and (firing_ball_y_t < RTWO_y_b)and (RTWO_y_b < firing_ball_y_t)and (RTWO_x_l < firing_ball_x_r))and refr_tick = '1')
    else hit_cnt_reg;
    RThree_x_next <= (others=> '0') when(((firing_ball_x_l < RThree_x_r)
            and (firing_ball_y_t < RTHREE_y_b))and refr_tick = '1') else
    hit_cnt_reg+1 when (((firing_ball_x_r < RTHREE_x_l) and (firing_ball_y_t < RTHREE_y_b)and (RTHREE_y_b < firing_ball_y_t)and (RTHREE_x_l < firing_ball_x_r))and refr_tick = '1')
    else hit_cnt_reg;

end sq_ball_arch;

