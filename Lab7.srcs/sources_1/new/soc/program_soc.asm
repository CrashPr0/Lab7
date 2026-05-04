# Assembly for SoC Factorial with Button Trigger
# Address Map:
# 0x800: Switches (Read)
# 0x808: Button (Read bit 0, Write to Clear)
# 0x900: LEDs (Write)
# 0xA00: Fact Ctrl (Bit 0: Go, Bit 1: Error, Bit 0: Done)
# 0xA04: Fact N (Write)
# 0xA08: Fact Result (Read)

main:
    # 1. Initialize addresses
    lui $t0, 0x0000
    ori $t0, $t0, 0x0800  # $t0 = GPIO Base (0x800)
    
    lui $t1, 0x0000
    ori $t1, $t1, 0x0A00  # $t1 = Fact Base (0xA00)
    
    lui $t4, 0x0000
    ori $t4, $t4, 0x0900  # $t4 = Display Base (0x900)

wait_for_btn:
    # 2. Poll for button press (offset 0x8 from 0x800)
    lw   $t2, 8($t0)      # Read button status
    andi $t2, $t2, 1      # Mask bit 0
    beq  $t2, $0, wait_for_btn

    # 3. Read N from switches (offset 0x0 from 0x800)
    lw  $a0, 0($t0)       # $a0 = switches
    
    # 4. Clear the button latch (write anything to 0x808)
    sw  $0, 8($t0)

    # 5. Write N to Factorial Accelerator
    sw  $a0, 4($t1)       # Write N to 0xA04

    # 6. Start Factorial (Go = 1)
    addi $t2, $0, 1
    sw   $t2, 0($t1)      # Write Go to 0xA00

poll_fact:
    # 7. Wait for Done
    lw   $t3, 0($t1)      # Read Status from 0xA00
    andi $t3, $t3, 1      # Mask bit 0 (Done)
    beq  $t3, $0, poll_fact

    # 8. Read Result
    lw   $v0, 8($t1)      # Read Result from 0xA08

    # 9. Display Result
    sw   $v0, 0($t4)      # Write Result to LEDs/7-seg

    # 10. Repeat
    j wait_for_btn
