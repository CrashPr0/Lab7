# Assembly for SoC Factorial Hardware Acceleration
# Address Map:
# 0x800: Switches (Read)
# 0x900: LEDs (Write)
# 0xA00: Fact Ctrl (Bit 0: Go, Bit 1: Error, Bit 0: Done)
# 0xA04: Fact N (Write)
# 0xA08: Fact Result (Read)

main:
    # 1. Read N from switches
    lui $t0, 0x0000
    ori $t0, $t0, 0x0800  # $t0 = 0x800
    lw  $a0, 0($t0)       # $a0 = switches

    # 2. Write N to Factorial Accelerator
    lui $t1, 0x0000
    ori $t1, $t1, 0x0A00  # $t1 = 0xA00
    sw  $a0, 4($t1)       # Write N to 0xA04

    # 3. Start Factorial (Go = 1)
    addi $t2, $0, 1
    sw   $t2, 0($t1)      # Write Go to 0xA00

poll:
    # 4. Wait for Done
    lw   $t3, 0($t1)      # Read Status from 0xA00
    andi $t3, $t3, 1      # Mask bit 0 (Done)
    beq  $t3, $0, poll    # if Done == 0, keep polling

    # 5. Read Result
    lw   $v0, 8($t1)      # Read Result from 0xA08

    # 6. Display Result
    lui  $t4, 0x0000
    ori  $t4, $t4, 0x0900 # $t4 = 0x900
    sw   $v0, 0($t4)      # Write Result to LEDs

end:
    j end
