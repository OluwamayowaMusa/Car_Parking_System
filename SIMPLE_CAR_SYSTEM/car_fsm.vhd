LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
ENTITY car_fsm IS
	PORT
	(clk,reset_btn: IN STD_LOGIC; -- clock and reset of the car parking system
	 signal_btn: IN STD_LOGIC; -- display number of cars and give permission to cars that stopped due to a car entering;
	 front_sensor, back_sensor: IN STD_LOGIC; -- two sensor in front and behind the gate of the car parking system
	 password: IN STD_LOGIC_VECTOR(3 downto 0); -- input password 
	 set_password: IN STD_LOGIC_VECTOR(3 DOWNTO 0); -- set password
	 status_led: OUT STD_LOGIC_VECTOR(3 DOWNTO 0); -- signaling LEDs
	 display5, display4, display3, display2, display1, display0: OUT STD_LOGIC_VECTOR(6 DOWNTO 0) -- 7-segment Display 
	);
END ENTITY car_fsm;

ARCHITECTURE behaviour of car_fsm IS
	--COMPONENTS
	COMPONENT int_to_bit IS
		PORT(number: IN INTEGER RANGE 0 TO 100;
		  display1, display0: OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
		  );
	END COMPONENT int_to_bit;
	
	-- STATES
	type STATE is (IDLE,WAIT_PASSWORD,WRONG_PASS,RIGHT_PASS,STOP, GOING_OUT, NO_SPACE);
	
	-- The status led shows
	-- `0000` -> IDLE
	-- `0011` -> WAIT_PASSWORD
	-- `1111` -> WRONG_PASS
	-- `1100` -> RIGHT_PASS
	-- `1010` -> STOP
	-- `1110` -> GOING_OUT
	-- `0111` -> NO_SPACE

 	-- SIGNALS
	SIGNAL current_state,next_state: STATE;
	SIGNAL time_to_inspect_car: INTEGER RANGE 0 TO 20 := 0;
	SIGNAL red_tmp, green_tmp: std_logic;
	SIGNAL clk_1hz: STD_LOGIC; -- 1 Hz clock to keep track of time
	SIGNAL number_of_cars: INTEGeR RANGE 0 TO 100 := 0;
	SIGNAL display1_number_of_car: STD_LOGIC_VECTOR(6 DOWNTO 0);
	SIGNAL display0_number_of_car: STD_LOGIC_VECTOR(6 DOWNTO 0);
	
	-- CONSTANT
	CONSTANT INSPECTION_TIME: INTEGER := 10; -- INSPECTION TIME.
	CONSTANT MAX_NUMBER_OF_CARS: INTEGER := 5;
	
	
		-- DISPLAYS
	CONSTANT BLANK: STD_LOGIC_VECTOR(6 DOWNTO 0) := "1111111";
	--STATE IDLE
	CONSTANT IDLE_DISPLAY5: STD_LOGIC_VECTOR(6 DOWNTO 0) := BLANK;
	CONSTANT IDLE_DISPLAY4: STD_LOGIC_VECTOR(6 DOWNTO 0) := BLANK;
	CONSTANT IDLE_DISPLAY3: STD_LOGIC_VECTOR(6 DOWNTO 0) := "1111001"; --I
	CONSTANT IDLE_DISPLAY2: STD_LOGIC_VECTOR(6 DOWNTO 0) := "0100001"; --D
	CONSTANT IDLE_DISPLAY1: STD_LOGIC_VECTOR(6 DOWNTO 0) := "1000111"; --L
	CONSTANT IDLE_DISPLAY0: STD_LOGIC_VECTOR(6 DOWNTO 0) := "0000110"; --E
	CONSTANT IDLE_LED: STD_LOGIC_VECTOR(3 DOWNTO 0) := "0000";
	
	--STATE WAIT_PASS
	CONSTANT PSWRD_DISPLAY5: STD_LOGIC_VECTOR(6 DOWNTO 0) := "0001100"; --P
	CONSTANT PSWRD_DISPLAY4: STD_LOGIC_VECTOR(6 DOWNTO 0) := "0010010"; --S
	CONSTANT PSWRD_DISPLAY3: STD_LOGIC_VECTOR(6 DOWNTO 0) := "1000011"; --HALF W
	CONSTANT PSWRD_DISPLAY2: STD_LOGIC_VECTOR(6 DOWNTO 0) := "1100001"; --HALF W
	CONSTANT PSWRD_DISPLAY1: STD_LOGIC_VECTOR(6 DOWNTO 0) := "0101111"; --R
	CONSTANT PSWRD_DISPLAY0: STD_LOGIC_VECTOR(6 DOWNTO 0) := "0100001"; --D
	CONSTANT PSWRD_LED: STD_LOGIC_VECTOR(3 DOWNTO 0) := "0011";
	
	--STATE WRONG_PASS
	CONSTANT WRG_DISPLAY5: STD_LOGIC_VECTOR(6 DOWNTO 0) := "1000011"; --HALF W
	CONSTANT WRG_DISPLAY4: STD_LOGIC_VECTOR(6 DOWNTO 0) := "1100001"; --HALF W
	CONSTANT WRG_DISPLAY3: STD_LOGIC_VECTOR(6 DOWNTO 0) := "0101111"; --R
	CONSTANT WRG_DISPLAY2: STD_LOGIC_VECTOR(6 DOWNTO 0) := "1000000"; --O
	CONSTANT WRG_DISPLAY1: STD_LOGIC_VECTOR(6 DOWNTO 0) := "1001000"; --N
	CONSTANT WRG_DISPLAY0: STD_LOGIC_VECTOR(6 DOWNTO 0) := "0010000"; --G
	CONSTANT WRG_LED: STD_LOGIC_VECTOR(3 DOWNTO 0) := "1111";
	
	--STATE RIGHT_PASS
	CONSTANT RHT_DISPLAY5: STD_LOGIC_VECTOR(6 DOWNTO 0) := BLANK;
	CONSTANT RHT_DISPLAY4: STD_LOGIC_VECTOR(6 DOWNTO 0) := "0101111"; --R
	CONSTANT RHT_DISPLAY3: STD_LOGIC_VECTOR(6 DOWNTO 0) := "1111001"; --I
	CONSTANT RHT_DISPLAY2: STD_LOGIC_VECTOR(6 DOWNTO 0) := "0010000"; --G
	CONSTANT RHT_DISPLAY1: STD_LOGIC_VECTOR(6 DOWNTO 0) := "0001001"; --H
	CONSTANT RHT_DISPLAY0: STD_LOGIC_VECTOR(6 DOWNTO 0) := "0000111"; --T
	CONSTANT RHT_LED: STD_LOGIC_VECTOR(3 DOWNTO 0) := "1100";
	
	--STATE STOP
	CONSTANT STOP_DISPLAY5: STD_LOGIC_VECTOR(6 DOWNTO 0) := BLANK;
	CONSTANT STOP_DISPLAY4: STD_LOGIC_VECTOR(6 DOWNTO 0) := BLANK;
	CONSTANT STOP_DISPLAY3: STD_LOGIC_VECTOR(6 DOWNTO 0) := "0010010"; --S
	CONSTANT STOP_DISPLAY2: STD_LOGIC_VECTOR(6 DOWNTO 0) := "0000111"; --T
	CONSTANT STOP_DISPLAY1: STD_LOGIC_VECTOR(6 DOWNTO 0) := "1000000"; --O
	CONSTANT STOP_DISPLAY0: STD_LOGIC_VECTOR(6 DOWNTO 0) := "0001100"; --P
	CONSTANT STOP_LED: STD_LOGIC_VECTOR(3 DOWNTO 0) := "1010";
	
	--STATE GOING_OUT
	CONSTANT GO_OUT_DISPLAY5: STD_LOGIC_VECTOR(6 DOWNTO 0) := "0010000"; --G
	CONSTANT GO_OUT_DISPLAY4: STD_LOGIC_VECTOR(6 DOWNTO 0) := "1000000"; --O
	CONSTANT GO_OUT_DISPLAY3: STD_LOGIC_VECTOR(6 DOWNTO 0) := BLANK;
	CONSTANT GO_OUT_DISPLAY2: STD_LOGIC_VECTOR(6 DOWNTO 0) := "1000000"; --O
	CONSTANT GO_OUT_DISPLAY1: STD_LOGIC_VECTOR(6 DOWNTO 0) := "1000001"; --U
	CONSTANT GO_OUT_DISPLAY0: STD_LOGIC_VECTOR(6 DOWNTO 0) := "0000111"; --T
	CONSTANT GO_OUT_LED: STD_LOGIC_VECTOR(3 DOWNTO 0) := "1110";
	
	--STATE NO_SPACE
	CONSTANT NO_SPACE_DISPLAY5: STD_LOGIC_VECTOR(6 DOWNTO 0) := BLANK;
	CONSTANT NO_SPACE_DISPLAY4: STD_LOGIC_VECTOR(6 DOWNTO 0) := BLANK;
	CONSTANT NO_SPACE_DISPLAY3: STD_LOGIC_VECTOR(6 DOWNTO 0) := "0001110"; --F
	CONSTANT NO_SPACE_DISPLAY2: STD_LOGIC_VECTOR(6 DOWNTO 0) := "1000001"; --U
	CONSTANT NO_SPACE_DISPLAY1: STD_LOGIC_VECTOR(6 DOWNTO 0) := "1000111"; --L
	CONSTANT NO_SPACE_DISPLAY0: STD_LOGIC_VECTOR(6 DOWNTO 0) := "1000111"; --L
	CONSTANT NO_SPACE_LED: STD_LOGIC_VECTOR(3 DOWNTO 0) := "0111";
	
BEGIN
	display_number_of_cars: int_to_bit PORT MAP(number => number_of_cars,
															  display1 => display1_number_of_car,
															  display0 => display0_number_of_car
															  );
															  
	create_1Hz_clock: PROCESS(clk, reset_btn)
	VARIABLE delay: INTEGER RANGE 0 TO 50e6;
	BEGIN
		IF reset_btn = '0' THEN
			delay := 0;
		ELSIF rising_edge(clk) THEN
			IF delay >= 25e6 THEN
				clk_1hz <= NOT clk_1hz;
				delay := 0;
			ELSE
				delay := delay + 1;
			END IF;
		END IF;
	END PROCESS;
	
	transistion_logic: PROCESS(clk_1hz, reset_btn, next_state)
	BEGIN
		IF reset_btn = '0' THEN
			current_state <= IDLE;
		ELSE
			current_state <= next_state;
		END IF;
	END PROCESS;
	
	state_logic: PROCESS(front_sensor, back_sensor, password, clk_1hz, signal_btn, reset_btn)
	BEGIN
		IF reset_btn = '0' THEN
			next_state <= IDLE;
		ELSIF rising_edge(clk_1hz) THEN
			CASE current_state IS
				WHEN IDLE =>
					IF front_sensor = '1' THEN
						IF number_of_cars >= MAX_NUMBER_OF_CARS THEN
							next_state <= NO_SPACE;
						ELSE
							next_state <= WAIT_PASSWORD;
						END IF;
					ELSIF back_sensor = '1' THEN
						IF number_of_cars > 0 THEN
							next_state <= GOING_OUT;
						ELSE
							next_state <= IDLE;
						END IF;
					ELSE
						next_state <= IDLE;
					END IF;
				
				WHEN WAIT_PASSWORD =>
					IF time_to_inspect_car <= INSPECTION_TIME THEN
						next_state <= WAIT_PASSWORD; -- Check for password after duration of time
					ELSE
						IF password = set_password THEN 
							next_state <= RIGHT_PASS; -- Let car in if password is correct
						ELSE
							next_state <= WRONG_PASS; -- Ask for password again if password is wrong
						END IF;
					END IF;
					
				WHEN WRONG_PASS =>
					IF password = set_password THEN
						next_state <= RIGHT_PASS; -- Let car on wrong password
					ELSE
						next_state <= WRONG_PASS; -- Remain in wrong password
					END IF;
					
				WHEN RIGHT_PASS =>
					IF back_sensor = '1' THEN
						number_of_cars <= number_of_cars + 1; -- Increase Number of cars
						IF front_sensor = '1' THEN -- Car is approching as car is entering
							next_state <= STOP;
						ELSE
							next_state <= IDLE;
						END IF;
					END IF;
					
				WHEN STOP =>
					IF signal_btn = '0' THEN
						IF number_of_cars >= MAX_NUMBER_OF_CARS THEN
							next_state <= NO_SPACE;
						ELSE
							next_state <= WAIT_PASSWORD;
						END IF;
					ELSE
						next_state <= STOP;
					END IF;
					
				WHEN GOING_OUT =>
					IF number_of_cars > 0 THEN
						number_of_cars <= number_of_cars - 1;
						next_state <= IDLE;
					ELSIF front_sensor = '1' THEN
						next_state <= IDLE;
					ELSE
						next_state <= GOING_OUT;
					END IF;
					
				WHEN NO_SPACE =>
					IF back_sensor = '1' THEN
						next_state <= GOING_OUT;
					ELSE
						next_state <= NO_SPACE;
					END IF;
					
			END CASE;
		END IF;
	END PROCESS;
	
	keep_track_of_time: PROCESS(time_to_inspect_car, clk_1hz)
	BEGIN
		IF reset_btn = '0' THEN
			time_to_inspect_car <= 0;
		ELSIF current_state = WAIT_PASSWORD THEN
			IF rising_edge(clk_1hz) THEN
				time_to_inspect_car <= time_to_inspect_car + 1;
			END IF;
		ELSE
			time_to_inspect_car <= 0;
		END IF;
	END PROCESS;
	
	output_logic: PROCESS(current_state, signal_btn)
	BEGIN
		IF signal_btn = '0' AND current_state /= STOP THEN
			display5 <= BLANK;
			display4 <= BLANK;
			display3 <= BLANK;
			display2 <= BLANK;
			display1 <= display1_number_of_car;
			display0 <= display0_number_of_car;
		ELSE
			CASE current_state IS
				WHEN IDLE =>
					display5 <= IDLE_DISPLAY5;
					display4 <= IDLE_DISPLAY4;
					display3 <= IDLE_DISPLAY3;
					display2 <= IDLE_DISPLAY2;
					display1 <= IDLE_DISPLAY1;
					display0 <= IDLE_DISPLAY0;
					status_led <= IDLE_LED;
					
				WHEN WAIT_PASSWORD =>
					display5 <= PSWRD_DISPLAY5;
					display4 <= PSWRD_DISPLAY4;
					display3 <= PSWRD_DISPLAY3;
					display2 <= PSWRD_DISPLAY2;
					display1 <= PSWRD_DISPLAY1;
					display0 <= PSWRD_DISPLAY0;
					status_led <= PSWRD_LED;
					
				WHEN WRONG_PASS =>
					display5 <= WRG_DISPLAY5;
					display4 <= WRG_DISPLAY4;
					display3 <= WRG_DISPLAY3;
					display2 <= WRG_DISPLAY2;
					display1 <= WRG_DISPLAY1;
					display0 <= WRG_DISPLAY0;
					status_led <= WRG_LED;
						
				WHEN RIGHT_PASS =>
					display5 <= RHT_DISPLAY5;
					display4 <= RHT_DISPLAY4;
					display3 <= RHT_DISPLAY3;
					display2 <= RHT_DISPLAY2;
					display1 <= RHT_DISPLAY1;
					display0 <= RHT_DISPLAY0;
					status_led <= RHT_LED;
					
				WHEN STOP =>
					display5 <= STOP_DISPLAY5;
					display4 <= STOP_DISPLAY4;
					display3 <= STOP_DISPLAY3;
					display2 <= STOP_DISPLAY2;
					display1 <= STOP_DISPLAY1;
					display0 <= STOP_DISPLAY0;
					status_led <= STOP_LED;
					
				WHEN GOING_OUT =>
					display5 <= GO_OUT_DISPLAY5;
					display4 <= GO_OUT_DISPLAY4;
					display3 <= GO_OUT_DISPLAY3;
					display2 <= GO_OUT_DISPLAY2;
					display1 <= GO_OUT_DISPLAY1;
					display0 <= GO_OUT_DISPLAY0;
					status_led <= GO_OUT_LED;
					
				WHEN NO_SPACE =>
					display5 <= NO_SPACE_DISPLAY5;
					display4 <= NO_SPACE_DISPLAY4;
					display3 <= NO_SPACE_DISPLAY3;
					display2 <= NO_SPACE_DISPLAY2;
					display1 <= NO_SPACE_DISPLAY1;
					display0 <= NO_SPACE_DISPLAY0;
					status_led <= NO_SPACE_LED;
					
			END CASE;
		END IF;
	END PROCESS;
	
END ARCHITECTURE behaviour;