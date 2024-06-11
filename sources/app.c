#include "float_adder_ip.h"
#include "xil_io.h"
#include "xparameters.h"
#include "xuartps.h"

#define UART_DEVICE_ID XPAR_XUARTPS_0_DEVICE_ID

//====================================================
XUartPs Uart_Ps;
XUartPs_Config *Config;

static char charopA32[] = "00000000";
static char charopB32[] = "00000000";
static char charopA64[] = "0000000000000000";
static char charopB64[] = "0000000000000000";
static char option[] = "0";

uint32_t hex2int(char *hex) {
  uint32_t val = 0;
  while (*hex) {
    // get current character then increment
    uint8_t byte = *hex++;
    // transform hex character to the 4bit equivalent number, using the ascii
    // table indexes
    if (byte >= '0' && byte <= '9')
      byte = byte - '0';
    else if (byte >= 'a' && byte <= 'f')
      byte = byte - 'a' + 10;
    else if (byte >= 'A' && byte <= 'F')
      byte = byte - 'A' + 10;
    // shift 4 to make space for new digit, and add the 4 bits of the new digit
    val = (val << 4) | (byte & 0xF);
  }
  return val;
}

uint64_t hex2int64(char *hex) {
  uint64_t val = 0;
  while (*hex) {
    // get current character then increment
    uint8_t byte = *hex++;
    // transform hex character to the 4bit equivalent number, using the ascii
    // table indexes
    if (byte >= '0' && byte <= '9')
      byte = byte - '0';
    else if (byte >= 'a' && byte <= 'f')
      byte = byte - 'a' + 10;
    else if (byte >= 'A' && byte <= 'F')
      byte = byte - 'A' + 10;
    // shift 4 to make space for new digit, and add the 4 bits of the new digit
    val = (val << 4) | (byte & 0xF);
  }
  return val;
}

void sum32bits() {

  xil_printf("Ingrese operando A de 32 bits ...\n\r");
  for (int i = 0; i < 8; i++) {
    xil_printf("Ingrese %d/7 \r\n", i);
    charopA32[i] = XUartPs_RecvByte(Config->BaseAddress);
    xil_printf("Num ingresado %c \r\n", charopA32[i]);
  }
  xil_printf("Ingrese operando B de 32 bits ...\n\r");

  for (int i = 0; i < 8; i++) {
    xil_printf("Ingrese %d/7 \r\n", i);
    charopB32[i] = XUartPs_RecvByte(Config->BaseAddress);
    xil_printf("Num ingresado %c \r\n", charopB32[i]);
  }

  uint32_t opA = hex2int(charopA32);
  uint32_t opB = hex2int(charopB32);
  int start = 0x1;
  xil_printf("******************** \r\n");
  xil_printf("Inicio de Float Adder \r\n");
  xil_printf("******************** \r\n");

  FLOAT_ADDER_IP_mWriteReg(XPAR_FLOAT_ADDER_IP_32BITS_S_AXI_BASEADDR,
                           FLOAT_ADDER_IP_S_AXI_SLV_REG0_OFFSET, opA);
  FLOAT_ADDER_IP_mWriteReg(XPAR_FLOAT_ADDER_IP_32BITS_S_AXI_BASEADDR,
                           FLOAT_ADDER_IP_S_AXI_SLV_REG2_OFFSET, opB);
  FLOAT_ADDER_IP_mWriteReg(XPAR_FLOAT_ADDER_IP_32BITS_S_AXI_BASEADDR,
                           FLOAT_ADDER_IP_S_AXI_SLV_REG4_OFFSET, start);
  start = 0;
  FLOAT_ADDER_IP_mWriteReg(XPAR_FLOAT_ADDER_IP_32BITS_S_AXI_BASEADDR,
                           FLOAT_ADDER_IP_S_AXI_SLV_REG4_OFFSET, start);

  while (0 == FLOAT_ADDER_IP_mReadReg(XPAR_FLOAT_ADDER_IP_32BITS_S_AXI_BASEADDR,
                                      FLOAT_ADDER_IP_S_AXI_SLV_REG7_OFFSET))
    ;

  uint32_t res =
      FLOAT_ADDER_IP_mReadReg(XPAR_FLOAT_ADDER_IP_32BITS_S_AXI_BASEADDR,
                              FLOAT_ADDER_IP_S_AXI_SLV_REG5_OFFSET);

  xil_printf("OP A = 0x%x\n\r", opA);
  xil_printf("OP B = 0x%x\n\r", opB);
  xil_printf("RES  = 0x%x\n\r", res);
}

void sum64bits() {

  xil_printf("Ingrese operando A de 64 bits ...\n\r");
  for (int i = 0; i < 16; i++) {
    xil_printf("Ingrese %d/15 \r\n", i);
    charopA64[i] = XUartPs_RecvByte(Config->BaseAddress);
    xil_printf("Num ingresado %c \r\n", charopA64[i]);
  }

  xil_printf("Ingrese operando B de 64 bits ...\n\r");

  for (int i = 0; i < 16; i++) {
    xil_printf("Ingrese %d/15 \r\n", i);
    charopB64[i] = XUartPs_RecvByte(Config->BaseAddress);
    xil_printf("Num ingresado %c \r\n", charopB64[i]);
  }

  uint64_t opA = hex2int64(charopA64);
  uint64_t opB = hex2int64(charopB64);
  uint64_t opAA = 0x1234567812345678;
  xil_printf("OP AA = 0x%x\n\r", opAA);
  xil_printf("OP A = 0x%x\n\r", opA);
  xil_printf("OP B = 0x%x\n\r", opB);

  uint32_t opAlow = opA;
  uint32_t opAhigh = opA >> 32;
  uint32_t opBlow = opB;
  uint32_t opBhigh = opB >> 32;

  int start = 0x1;
  xil_printf("******************** \r\n");
  xil_printf("Inicio de Float Adder \r\n");
  xil_printf("******************** \r\n");

  FLOAT_ADDER_IP_mWriteReg(XPAR_FLOAT_ADDER_IP_64BITS_S_AXI_BASEADDR,
                           FLOAT_ADDER_IP_S_AXI_SLV_REG0_OFFSET, opAlow);
  FLOAT_ADDER_IP_mWriteReg(XPAR_FLOAT_ADDER_IP_64BITS_S_AXI_BASEADDR,
                           FLOAT_ADDER_IP_S_AXI_SLV_REG1_OFFSET, opAhigh);
  FLOAT_ADDER_IP_mWriteReg(XPAR_FLOAT_ADDER_IP_64BITS_S_AXI_BASEADDR,
                           FLOAT_ADDER_IP_S_AXI_SLV_REG2_OFFSET, opBlow);
  FLOAT_ADDER_IP_mWriteReg(XPAR_FLOAT_ADDER_IP_64BITS_S_AXI_BASEADDR,
                           FLOAT_ADDER_IP_S_AXI_SLV_REG3_OFFSET, opBhigh);
  FLOAT_ADDER_IP_mWriteReg(XPAR_FLOAT_ADDER_IP_64BITS_S_AXI_BASEADDR,
                           FLOAT_ADDER_IP_S_AXI_SLV_REG4_OFFSET, start);
  start = 0;
  FLOAT_ADDER_IP_mWriteReg(XPAR_FLOAT_ADDER_IP_64BITS_S_AXI_BASEADDR,
                           FLOAT_ADDER_IP_S_AXI_SLV_REG4_OFFSET, start);

  while (0 == FLOAT_ADDER_IP_mReadReg(XPAR_FLOAT_ADDER_IP_64BITS_S_AXI_BASEADDR,
                                      FLOAT_ADDER_IP_S_AXI_SLV_REG7_OFFSET))
    ;

  uint32_t res_low =
      FLOAT_ADDER_IP_mReadReg(XPAR_FLOAT_ADDER_IP_64BITS_S_AXI_BASEADDR,
                              FLOAT_ADDER_IP_S_AXI_SLV_REG5_OFFSET);
  uint32_t res_high =
      FLOAT_ADDER_IP_mReadReg(XPAR_FLOAT_ADDER_IP_64BITS_S_AXI_BASEADDR,
                              FLOAT_ADDER_IP_S_AXI_SLV_REG6_OFFSET);
  uint64_t res = ((uint64_t)res_high << 32) | res_low;
  xil_printf("OP A = 0x%x\n\r", opA);
  xil_printf("OP B = 0x%x\n\r", opB);
  xil_printf("RES  = 0x%x\n\r", res);
}

int main(void) {

  Config = XUartPs_LookupConfig(UART_DEVICE_ID);
  XUartPs_CfgInitialize(&Uart_Ps, Config, Config->BaseAddress);

  xil_printf("***************************************************** \r\n");
  xil_printf("-- Bienvenido al sumador de punto floante 32 o 64bits \r\n");
  xil_printf("***************************************************** \r\n");

  while (1) {

    xil_printf(
        "Ingrese 1 si la suma es en 32bits o 2 si la suma es en 64 bits  \r\n");
    option[0] = XUartPs_RecvByte(Config->BaseAddress);
    uint32_t op = hex2int(option);
    xil_printf("******************** \r\n");
    xil_printf("Sumador de %d bits n\r", 32 * op);
    xil_printf("******************** \r\n");
    if (op == 1) {
      sum32bits();
    } else if (op == 2) {
       xil_printf("******************** \r\n");
      xil_printf("No implementado\r\n");
      xil_printf("******************** \r\n");
    } else {
      xil_printf("******************** \r\n");
      xil_printf("No válido\r\n");
      xil_printf("******************** \r\n");
    }
  }
}
