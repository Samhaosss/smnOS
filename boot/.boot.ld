OUTPUT_FORMAT(elf32-i386)
OUTPUT_ARCH(i386)

SECTIONS{
	/*将所有文件的text段整合*/
	.text 0x0000 : { 
		*(.text)
	}
	/DISCARD/ : {

	}
}
