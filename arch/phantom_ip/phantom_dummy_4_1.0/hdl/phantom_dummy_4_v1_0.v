
`timescale 1 ns / 1 ps

	module phantom_dummy_4_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Master Bus Interface M00_AXI
		parameter  C_M00_AXI_TARGET_SLAVE_BASE_ADDR	= 32'h40000000,
		parameter integer C_M00_AXI_BURST_LEN	= 16,
		parameter integer C_M00_AXI_ID_WIDTH	= 1,
		parameter integer C_M00_AXI_ADDR_WIDTH	= 32,
		parameter integer C_M00_AXI_DATA_WIDTH	= 32,
		parameter integer C_M00_AXI_AWUSER_WIDTH	= 0,
		parameter integer C_M00_AXI_ARUSER_WIDTH	= 0,
		parameter integer C_M00_AXI_WUSER_WIDTH	= 0,
		parameter integer C_M00_AXI_RUSER_WIDTH	= 0,
		parameter integer C_M00_AXI_BUSER_WIDTH	= 0,

		// Parameters of Axi Master Bus Interface M01_AXI
		parameter  C_M01_AXI_TARGET_SLAVE_BASE_ADDR	= 32'h40000000,
		parameter integer C_M01_AXI_BURST_LEN	= 16,
		parameter integer C_M01_AXI_ID_WIDTH	= 1,
		parameter integer C_M01_AXI_ADDR_WIDTH	= 32,
		parameter integer C_M01_AXI_DATA_WIDTH	= 32,
		parameter integer C_M01_AXI_AWUSER_WIDTH	= 0,
		parameter integer C_M01_AXI_ARUSER_WIDTH	= 0,
		parameter integer C_M01_AXI_WUSER_WIDTH	= 0,
		parameter integer C_M01_AXI_RUSER_WIDTH	= 0,
		parameter integer C_M01_AXI_BUSER_WIDTH	= 0,

		// Parameters of Axi Master Bus Interface M02_AXI
		parameter  C_M02_AXI_TARGET_SLAVE_BASE_ADDR	= 32'h40000000,
		parameter integer C_M02_AXI_BURST_LEN	= 16,
		parameter integer C_M02_AXI_ID_WIDTH	= 1,
		parameter integer C_M02_AXI_ADDR_WIDTH	= 32,
		parameter integer C_M02_AXI_DATA_WIDTH	= 32,
		parameter integer C_M02_AXI_AWUSER_WIDTH	= 0,
		parameter integer C_M02_AXI_ARUSER_WIDTH	= 0,
		parameter integer C_M02_AXI_WUSER_WIDTH	= 0,
		parameter integer C_M02_AXI_RUSER_WIDTH	= 0,
		parameter integer C_M02_AXI_BUSER_WIDTH	= 0,

		// Parameters of Axi Master Bus Interface M03_AXI
		parameter  C_M03_AXI_TARGET_SLAVE_BASE_ADDR	= 32'h40000000,
		parameter integer C_M03_AXI_BURST_LEN	= 16,
		parameter integer C_M03_AXI_ID_WIDTH	= 1,
		parameter integer C_M03_AXI_ADDR_WIDTH	= 32,
		parameter integer C_M03_AXI_DATA_WIDTH	= 32,
		parameter integer C_M03_AXI_AWUSER_WIDTH	= 0,
		parameter integer C_M03_AXI_ARUSER_WIDTH	= 0,
		parameter integer C_M03_AXI_WUSER_WIDTH	= 0,
		parameter integer C_M03_AXI_RUSER_WIDTH	= 0,
		parameter integer C_M03_AXI_BUSER_WIDTH	= 0,

		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 4
	)
	(
		// Users to add ports here

		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Master Bus Interface M00_AXI
		input wire  m00_axi_init_axi_txn,
		output wire  m00_axi_txn_done,
		output wire  m00_axi_error,
		input wire  m00_axi_aclk,
		input wire  m00_axi_aresetn,
		output wire [C_M00_AXI_ID_WIDTH-1 : 0] m00_axi_awid,
		output wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_awaddr,
		output wire [7 : 0] m00_axi_awlen,
		output wire [2 : 0] m00_axi_awsize,
		output wire [1 : 0] m00_axi_awburst,
		output wire  m00_axi_awlock,
		output wire [3 : 0] m00_axi_awcache,
		output wire [2 : 0] m00_axi_awprot,
		output wire [3 : 0] m00_axi_awqos,
		output wire [C_M00_AXI_AWUSER_WIDTH-1 : 0] m00_axi_awuser,
		output wire  m00_axi_awvalid,
		input wire  m00_axi_awready,
		output wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_wdata,
		output wire [C_M00_AXI_DATA_WIDTH/8-1 : 0] m00_axi_wstrb,
		output wire  m00_axi_wlast,
		output wire [C_M00_AXI_WUSER_WIDTH-1 : 0] m00_axi_wuser,
		output wire  m00_axi_wvalid,
		input wire  m00_axi_wready,
		input wire [C_M00_AXI_ID_WIDTH-1 : 0] m00_axi_bid,
		input wire [1 : 0] m00_axi_bresp,
		input wire [C_M00_AXI_BUSER_WIDTH-1 : 0] m00_axi_buser,
		input wire  m00_axi_bvalid,
		output wire  m00_axi_bready,
		output wire [C_M00_AXI_ID_WIDTH-1 : 0] m00_axi_arid,
		output wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_araddr,
		output wire [7 : 0] m00_axi_arlen,
		output wire [2 : 0] m00_axi_arsize,
		output wire [1 : 0] m00_axi_arburst,
		output wire  m00_axi_arlock,
		output wire [3 : 0] m00_axi_arcache,
		output wire [2 : 0] m00_axi_arprot,
		output wire [3 : 0] m00_axi_arqos,
		output wire [C_M00_AXI_ARUSER_WIDTH-1 : 0] m00_axi_aruser,
		output wire  m00_axi_arvalid,
		input wire  m00_axi_arready,
		input wire [C_M00_AXI_ID_WIDTH-1 : 0] m00_axi_rid,
		input wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_rdata,
		input wire [1 : 0] m00_axi_rresp,
		input wire  m00_axi_rlast,
		input wire [C_M00_AXI_RUSER_WIDTH-1 : 0] m00_axi_ruser,
		input wire  m00_axi_rvalid,
		output wire  m00_axi_rready,

		// Ports of Axi Master Bus Interface M01_AXI
		input wire  m01_axi_init_axi_txn,
		output wire  m01_axi_txn_done,
		output wire  m01_axi_error,
		input wire  m01_axi_aclk,
		input wire  m01_axi_aresetn,
		output wire [C_M01_AXI_ID_WIDTH-1 : 0] m01_axi_awid,
		output wire [C_M01_AXI_ADDR_WIDTH-1 : 0] m01_axi_awaddr,
		output wire [7 : 0] m01_axi_awlen,
		output wire [2 : 0] m01_axi_awsize,
		output wire [1 : 0] m01_axi_awburst,
		output wire  m01_axi_awlock,
		output wire [3 : 0] m01_axi_awcache,
		output wire [2 : 0] m01_axi_awprot,
		output wire [3 : 0] m01_axi_awqos,
		output wire [C_M01_AXI_AWUSER_WIDTH-1 : 0] m01_axi_awuser,
		output wire  m01_axi_awvalid,
		input wire  m01_axi_awready,
		output wire [C_M01_AXI_DATA_WIDTH-1 : 0] m01_axi_wdata,
		output wire [C_M01_AXI_DATA_WIDTH/8-1 : 0] m01_axi_wstrb,
		output wire  m01_axi_wlast,
		output wire [C_M01_AXI_WUSER_WIDTH-1 : 0] m01_axi_wuser,
		output wire  m01_axi_wvalid,
		input wire  m01_axi_wready,
		input wire [C_M01_AXI_ID_WIDTH-1 : 0] m01_axi_bid,
		input wire [1 : 0] m01_axi_bresp,
		input wire [C_M01_AXI_BUSER_WIDTH-1 : 0] m01_axi_buser,
		input wire  m01_axi_bvalid,
		output wire  m01_axi_bready,
		output wire [C_M01_AXI_ID_WIDTH-1 : 0] m01_axi_arid,
		output wire [C_M01_AXI_ADDR_WIDTH-1 : 0] m01_axi_araddr,
		output wire [7 : 0] m01_axi_arlen,
		output wire [2 : 0] m01_axi_arsize,
		output wire [1 : 0] m01_axi_arburst,
		output wire  m01_axi_arlock,
		output wire [3 : 0] m01_axi_arcache,
		output wire [2 : 0] m01_axi_arprot,
		output wire [3 : 0] m01_axi_arqos,
		output wire [C_M01_AXI_ARUSER_WIDTH-1 : 0] m01_axi_aruser,
		output wire  m01_axi_arvalid,
		input wire  m01_axi_arready,
		input wire [C_M01_AXI_ID_WIDTH-1 : 0] m01_axi_rid,
		input wire [C_M01_AXI_DATA_WIDTH-1 : 0] m01_axi_rdata,
		input wire [1 : 0] m01_axi_rresp,
		input wire  m01_axi_rlast,
		input wire [C_M01_AXI_RUSER_WIDTH-1 : 0] m01_axi_ruser,
		input wire  m01_axi_rvalid,
		output wire  m01_axi_rready,

		// Ports of Axi Master Bus Interface M02_AXI
		input wire  m02_axi_init_axi_txn,
		output wire  m02_axi_txn_done,
		output wire  m02_axi_error,
		input wire  m02_axi_aclk,
		input wire  m02_axi_aresetn,
		output wire [C_M02_AXI_ID_WIDTH-1 : 0] m02_axi_awid,
		output wire [C_M02_AXI_ADDR_WIDTH-1 : 0] m02_axi_awaddr,
		output wire [7 : 0] m02_axi_awlen,
		output wire [2 : 0] m02_axi_awsize,
		output wire [1 : 0] m02_axi_awburst,
		output wire  m02_axi_awlock,
		output wire [3 : 0] m02_axi_awcache,
		output wire [2 : 0] m02_axi_awprot,
		output wire [3 : 0] m02_axi_awqos,
		output wire [C_M02_AXI_AWUSER_WIDTH-1 : 0] m02_axi_awuser,
		output wire  m02_axi_awvalid,
		input wire  m02_axi_awready,
		output wire [C_M02_AXI_DATA_WIDTH-1 : 0] m02_axi_wdata,
		output wire [C_M02_AXI_DATA_WIDTH/8-1 : 0] m02_axi_wstrb,
		output wire  m02_axi_wlast,
		output wire [C_M02_AXI_WUSER_WIDTH-1 : 0] m02_axi_wuser,
		output wire  m02_axi_wvalid,
		input wire  m02_axi_wready,
		input wire [C_M02_AXI_ID_WIDTH-1 : 0] m02_axi_bid,
		input wire [1 : 0] m02_axi_bresp,
		input wire [C_M02_AXI_BUSER_WIDTH-1 : 0] m02_axi_buser,
		input wire  m02_axi_bvalid,
		output wire  m02_axi_bready,
		output wire [C_M02_AXI_ID_WIDTH-1 : 0] m02_axi_arid,
		output wire [C_M02_AXI_ADDR_WIDTH-1 : 0] m02_axi_araddr,
		output wire [7 : 0] m02_axi_arlen,
		output wire [2 : 0] m02_axi_arsize,
		output wire [1 : 0] m02_axi_arburst,
		output wire  m02_axi_arlock,
		output wire [3 : 0] m02_axi_arcache,
		output wire [2 : 0] m02_axi_arprot,
		output wire [3 : 0] m02_axi_arqos,
		output wire [C_M02_AXI_ARUSER_WIDTH-1 : 0] m02_axi_aruser,
		output wire  m02_axi_arvalid,
		input wire  m02_axi_arready,
		input wire [C_M02_AXI_ID_WIDTH-1 : 0] m02_axi_rid,
		input wire [C_M02_AXI_DATA_WIDTH-1 : 0] m02_axi_rdata,
		input wire [1 : 0] m02_axi_rresp,
		input wire  m02_axi_rlast,
		input wire [C_M02_AXI_RUSER_WIDTH-1 : 0] m02_axi_ruser,
		input wire  m02_axi_rvalid,
		output wire  m02_axi_rready,

		// Ports of Axi Master Bus Interface M03_AXI
		input wire  m03_axi_init_axi_txn,
		output wire  m03_axi_txn_done,
		output wire  m03_axi_error,
		input wire  m03_axi_aclk,
		input wire  m03_axi_aresetn,
		output wire [C_M03_AXI_ID_WIDTH-1 : 0] m03_axi_awid,
		output wire [C_M03_AXI_ADDR_WIDTH-1 : 0] m03_axi_awaddr,
		output wire [7 : 0] m03_axi_awlen,
		output wire [2 : 0] m03_axi_awsize,
		output wire [1 : 0] m03_axi_awburst,
		output wire  m03_axi_awlock,
		output wire [3 : 0] m03_axi_awcache,
		output wire [2 : 0] m03_axi_awprot,
		output wire [3 : 0] m03_axi_awqos,
		output wire [C_M03_AXI_AWUSER_WIDTH-1 : 0] m03_axi_awuser,
		output wire  m03_axi_awvalid,
		input wire  m03_axi_awready,
		output wire [C_M03_AXI_DATA_WIDTH-1 : 0] m03_axi_wdata,
		output wire [C_M03_AXI_DATA_WIDTH/8-1 : 0] m03_axi_wstrb,
		output wire  m03_axi_wlast,
		output wire [C_M03_AXI_WUSER_WIDTH-1 : 0] m03_axi_wuser,
		output wire  m03_axi_wvalid,
		input wire  m03_axi_wready,
		input wire [C_M03_AXI_ID_WIDTH-1 : 0] m03_axi_bid,
		input wire [1 : 0] m03_axi_bresp,
		input wire [C_M03_AXI_BUSER_WIDTH-1 : 0] m03_axi_buser,
		input wire  m03_axi_bvalid,
		output wire  m03_axi_bready,
		output wire [C_M03_AXI_ID_WIDTH-1 : 0] m03_axi_arid,
		output wire [C_M03_AXI_ADDR_WIDTH-1 : 0] m03_axi_araddr,
		output wire [7 : 0] m03_axi_arlen,
		output wire [2 : 0] m03_axi_arsize,
		output wire [1 : 0] m03_axi_arburst,
		output wire  m03_axi_arlock,
		output wire [3 : 0] m03_axi_arcache,
		output wire [2 : 0] m03_axi_arprot,
		output wire [3 : 0] m03_axi_arqos,
		output wire [C_M03_AXI_ARUSER_WIDTH-1 : 0] m03_axi_aruser,
		output wire  m03_axi_arvalid,
		input wire  m03_axi_arready,
		input wire [C_M03_AXI_ID_WIDTH-1 : 0] m03_axi_rid,
		input wire [C_M03_AXI_DATA_WIDTH-1 : 0] m03_axi_rdata,
		input wire [1 : 0] m03_axi_rresp,
		input wire  m03_axi_rlast,
		input wire [C_M03_AXI_RUSER_WIDTH-1 : 0] m03_axi_ruser,
		input wire  m03_axi_rvalid,
		output wire  m03_axi_rready,

		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready
	);
// Instantiation of Axi Bus Interface M00_AXI
	phantom_dummy_4_v1_0_M00_AXI # ( 
		.C_M_TARGET_SLAVE_BASE_ADDR(C_M00_AXI_TARGET_SLAVE_BASE_ADDR),
		.C_M_AXI_BURST_LEN(C_M00_AXI_BURST_LEN),
		.C_M_AXI_ID_WIDTH(C_M00_AXI_ID_WIDTH),
		.C_M_AXI_ADDR_WIDTH(C_M00_AXI_ADDR_WIDTH),
		.C_M_AXI_DATA_WIDTH(C_M00_AXI_DATA_WIDTH),
		.C_M_AXI_AWUSER_WIDTH(C_M00_AXI_AWUSER_WIDTH),
		.C_M_AXI_ARUSER_WIDTH(C_M00_AXI_ARUSER_WIDTH),
		.C_M_AXI_WUSER_WIDTH(C_M00_AXI_WUSER_WIDTH),
		.C_M_AXI_RUSER_WIDTH(C_M00_AXI_RUSER_WIDTH),
		.C_M_AXI_BUSER_WIDTH(C_M00_AXI_BUSER_WIDTH)
	) phantom_dummy_4_v1_0_M00_AXI_inst (
		.INIT_AXI_TXN(m00_axi_init_axi_txn),
		.TXN_DONE(m00_axi_txn_done),
		.ERROR(m00_axi_error),
		.M_AXI_ACLK(m00_axi_aclk),
		.M_AXI_ARESETN(m00_axi_aresetn),
		.M_AXI_AWID(m00_axi_awid),
		.M_AXI_AWADDR(m00_axi_awaddr),
		.M_AXI_AWLEN(m00_axi_awlen),
		.M_AXI_AWSIZE(m00_axi_awsize),
		.M_AXI_AWBURST(m00_axi_awburst),
		.M_AXI_AWLOCK(m00_axi_awlock),
		.M_AXI_AWCACHE(m00_axi_awcache),
		.M_AXI_AWPROT(m00_axi_awprot),
		.M_AXI_AWQOS(m00_axi_awqos),
		.M_AXI_AWUSER(m00_axi_awuser),
		.M_AXI_AWVALID(m00_axi_awvalid),
		.M_AXI_AWREADY(m00_axi_awready),
		.M_AXI_WDATA(m00_axi_wdata),
		.M_AXI_WSTRB(m00_axi_wstrb),
		.M_AXI_WLAST(m00_axi_wlast),
		.M_AXI_WUSER(m00_axi_wuser),
		.M_AXI_WVALID(m00_axi_wvalid),
		.M_AXI_WREADY(m00_axi_wready),
		.M_AXI_BID(m00_axi_bid),
		.M_AXI_BRESP(m00_axi_bresp),
		.M_AXI_BUSER(m00_axi_buser),
		.M_AXI_BVALID(m00_axi_bvalid),
		.M_AXI_BREADY(m00_axi_bready),
		.M_AXI_ARID(m00_axi_arid),
		.M_AXI_ARADDR(m00_axi_araddr),
		.M_AXI_ARLEN(m00_axi_arlen),
		.M_AXI_ARSIZE(m00_axi_arsize),
		.M_AXI_ARBURST(m00_axi_arburst),
		.M_AXI_ARLOCK(m00_axi_arlock),
		.M_AXI_ARCACHE(m00_axi_arcache),
		.M_AXI_ARPROT(m00_axi_arprot),
		.M_AXI_ARQOS(m00_axi_arqos),
		.M_AXI_ARUSER(m00_axi_aruser),
		.M_AXI_ARVALID(m00_axi_arvalid),
		.M_AXI_ARREADY(m00_axi_arready),
		.M_AXI_RID(m00_axi_rid),
		.M_AXI_RDATA(m00_axi_rdata),
		.M_AXI_RRESP(m00_axi_rresp),
		.M_AXI_RLAST(m00_axi_rlast),
		.M_AXI_RUSER(m00_axi_ruser),
		.M_AXI_RVALID(m00_axi_rvalid),
		.M_AXI_RREADY(m00_axi_rready)
	);

// Instantiation of Axi Bus Interface M01_AXI
	phantom_dummy_4_v1_0_M01_AXI # ( 
		.C_M_TARGET_SLAVE_BASE_ADDR(C_M01_AXI_TARGET_SLAVE_BASE_ADDR),
		.C_M_AXI_BURST_LEN(C_M01_AXI_BURST_LEN),
		.C_M_AXI_ID_WIDTH(C_M01_AXI_ID_WIDTH),
		.C_M_AXI_ADDR_WIDTH(C_M01_AXI_ADDR_WIDTH),
		.C_M_AXI_DATA_WIDTH(C_M01_AXI_DATA_WIDTH),
		.C_M_AXI_AWUSER_WIDTH(C_M01_AXI_AWUSER_WIDTH),
		.C_M_AXI_ARUSER_WIDTH(C_M01_AXI_ARUSER_WIDTH),
		.C_M_AXI_WUSER_WIDTH(C_M01_AXI_WUSER_WIDTH),
		.C_M_AXI_RUSER_WIDTH(C_M01_AXI_RUSER_WIDTH),
		.C_M_AXI_BUSER_WIDTH(C_M01_AXI_BUSER_WIDTH)
	) phantom_dummy_4_v1_0_M01_AXI_inst (
		.INIT_AXI_TXN(m01_axi_init_axi_txn),
		.TXN_DONE(m01_axi_txn_done),
		.ERROR(m01_axi_error),
		.M_AXI_ACLK(m01_axi_aclk),
		.M_AXI_ARESETN(m01_axi_aresetn),
		.M_AXI_AWID(m01_axi_awid),
		.M_AXI_AWADDR(m01_axi_awaddr),
		.M_AXI_AWLEN(m01_axi_awlen),
		.M_AXI_AWSIZE(m01_axi_awsize),
		.M_AXI_AWBURST(m01_axi_awburst),
		.M_AXI_AWLOCK(m01_axi_awlock),
		.M_AXI_AWCACHE(m01_axi_awcache),
		.M_AXI_AWPROT(m01_axi_awprot),
		.M_AXI_AWQOS(m01_axi_awqos),
		.M_AXI_AWUSER(m01_axi_awuser),
		.M_AXI_AWVALID(m01_axi_awvalid),
		.M_AXI_AWREADY(m01_axi_awready),
		.M_AXI_WDATA(m01_axi_wdata),
		.M_AXI_WSTRB(m01_axi_wstrb),
		.M_AXI_WLAST(m01_axi_wlast),
		.M_AXI_WUSER(m01_axi_wuser),
		.M_AXI_WVALID(m01_axi_wvalid),
		.M_AXI_WREADY(m01_axi_wready),
		.M_AXI_BID(m01_axi_bid),
		.M_AXI_BRESP(m01_axi_bresp),
		.M_AXI_BUSER(m01_axi_buser),
		.M_AXI_BVALID(m01_axi_bvalid),
		.M_AXI_BREADY(m01_axi_bready),
		.M_AXI_ARID(m01_axi_arid),
		.M_AXI_ARADDR(m01_axi_araddr),
		.M_AXI_ARLEN(m01_axi_arlen),
		.M_AXI_ARSIZE(m01_axi_arsize),
		.M_AXI_ARBURST(m01_axi_arburst),
		.M_AXI_ARLOCK(m01_axi_arlock),
		.M_AXI_ARCACHE(m01_axi_arcache),
		.M_AXI_ARPROT(m01_axi_arprot),
		.M_AXI_ARQOS(m01_axi_arqos),
		.M_AXI_ARUSER(m01_axi_aruser),
		.M_AXI_ARVALID(m01_axi_arvalid),
		.M_AXI_ARREADY(m01_axi_arready),
		.M_AXI_RID(m01_axi_rid),
		.M_AXI_RDATA(m01_axi_rdata),
		.M_AXI_RRESP(m01_axi_rresp),
		.M_AXI_RLAST(m01_axi_rlast),
		.M_AXI_RUSER(m01_axi_ruser),
		.M_AXI_RVALID(m01_axi_rvalid),
		.M_AXI_RREADY(m01_axi_rready)
	);

// Instantiation of Axi Bus Interface M02_AXI
	phantom_dummy_4_v1_0_M02_AXI # ( 
		.C_M_TARGET_SLAVE_BASE_ADDR(C_M02_AXI_TARGET_SLAVE_BASE_ADDR),
		.C_M_AXI_BURST_LEN(C_M02_AXI_BURST_LEN),
		.C_M_AXI_ID_WIDTH(C_M02_AXI_ID_WIDTH),
		.C_M_AXI_ADDR_WIDTH(C_M02_AXI_ADDR_WIDTH),
		.C_M_AXI_DATA_WIDTH(C_M02_AXI_DATA_WIDTH),
		.C_M_AXI_AWUSER_WIDTH(C_M02_AXI_AWUSER_WIDTH),
		.C_M_AXI_ARUSER_WIDTH(C_M02_AXI_ARUSER_WIDTH),
		.C_M_AXI_WUSER_WIDTH(C_M02_AXI_WUSER_WIDTH),
		.C_M_AXI_RUSER_WIDTH(C_M02_AXI_RUSER_WIDTH),
		.C_M_AXI_BUSER_WIDTH(C_M02_AXI_BUSER_WIDTH)
	) phantom_dummy_4_v1_0_M02_AXI_inst (
		.INIT_AXI_TXN(m02_axi_init_axi_txn),
		.TXN_DONE(m02_axi_txn_done),
		.ERROR(m02_axi_error),
		.M_AXI_ACLK(m02_axi_aclk),
		.M_AXI_ARESETN(m02_axi_aresetn),
		.M_AXI_AWID(m02_axi_awid),
		.M_AXI_AWADDR(m02_axi_awaddr),
		.M_AXI_AWLEN(m02_axi_awlen),
		.M_AXI_AWSIZE(m02_axi_awsize),
		.M_AXI_AWBURST(m02_axi_awburst),
		.M_AXI_AWLOCK(m02_axi_awlock),
		.M_AXI_AWCACHE(m02_axi_awcache),
		.M_AXI_AWPROT(m02_axi_awprot),
		.M_AXI_AWQOS(m02_axi_awqos),
		.M_AXI_AWUSER(m02_axi_awuser),
		.M_AXI_AWVALID(m02_axi_awvalid),
		.M_AXI_AWREADY(m02_axi_awready),
		.M_AXI_WDATA(m02_axi_wdata),
		.M_AXI_WSTRB(m02_axi_wstrb),
		.M_AXI_WLAST(m02_axi_wlast),
		.M_AXI_WUSER(m02_axi_wuser),
		.M_AXI_WVALID(m02_axi_wvalid),
		.M_AXI_WREADY(m02_axi_wready),
		.M_AXI_BID(m02_axi_bid),
		.M_AXI_BRESP(m02_axi_bresp),
		.M_AXI_BUSER(m02_axi_buser),
		.M_AXI_BVALID(m02_axi_bvalid),
		.M_AXI_BREADY(m02_axi_bready),
		.M_AXI_ARID(m02_axi_arid),
		.M_AXI_ARADDR(m02_axi_araddr),
		.M_AXI_ARLEN(m02_axi_arlen),
		.M_AXI_ARSIZE(m02_axi_arsize),
		.M_AXI_ARBURST(m02_axi_arburst),
		.M_AXI_ARLOCK(m02_axi_arlock),
		.M_AXI_ARCACHE(m02_axi_arcache),
		.M_AXI_ARPROT(m02_axi_arprot),
		.M_AXI_ARQOS(m02_axi_arqos),
		.M_AXI_ARUSER(m02_axi_aruser),
		.M_AXI_ARVALID(m02_axi_arvalid),
		.M_AXI_ARREADY(m02_axi_arready),
		.M_AXI_RID(m02_axi_rid),
		.M_AXI_RDATA(m02_axi_rdata),
		.M_AXI_RRESP(m02_axi_rresp),
		.M_AXI_RLAST(m02_axi_rlast),
		.M_AXI_RUSER(m02_axi_ruser),
		.M_AXI_RVALID(m02_axi_rvalid),
		.M_AXI_RREADY(m02_axi_rready)
	);

// Instantiation of Axi Bus Interface M03_AXI
	phantom_dummy_4_v1_0_M03_AXI # ( 
		.C_M_TARGET_SLAVE_BASE_ADDR(C_M03_AXI_TARGET_SLAVE_BASE_ADDR),
		.C_M_AXI_BURST_LEN(C_M03_AXI_BURST_LEN),
		.C_M_AXI_ID_WIDTH(C_M03_AXI_ID_WIDTH),
		.C_M_AXI_ADDR_WIDTH(C_M03_AXI_ADDR_WIDTH),
		.C_M_AXI_DATA_WIDTH(C_M03_AXI_DATA_WIDTH),
		.C_M_AXI_AWUSER_WIDTH(C_M03_AXI_AWUSER_WIDTH),
		.C_M_AXI_ARUSER_WIDTH(C_M03_AXI_ARUSER_WIDTH),
		.C_M_AXI_WUSER_WIDTH(C_M03_AXI_WUSER_WIDTH),
		.C_M_AXI_RUSER_WIDTH(C_M03_AXI_RUSER_WIDTH),
		.C_M_AXI_BUSER_WIDTH(C_M03_AXI_BUSER_WIDTH)
	) phantom_dummy_4_v1_0_M03_AXI_inst (
		.INIT_AXI_TXN(m03_axi_init_axi_txn),
		.TXN_DONE(m03_axi_txn_done),
		.ERROR(m03_axi_error),
		.M_AXI_ACLK(m03_axi_aclk),
		.M_AXI_ARESETN(m03_axi_aresetn),
		.M_AXI_AWID(m03_axi_awid),
		.M_AXI_AWADDR(m03_axi_awaddr),
		.M_AXI_AWLEN(m03_axi_awlen),
		.M_AXI_AWSIZE(m03_axi_awsize),
		.M_AXI_AWBURST(m03_axi_awburst),
		.M_AXI_AWLOCK(m03_axi_awlock),
		.M_AXI_AWCACHE(m03_axi_awcache),
		.M_AXI_AWPROT(m03_axi_awprot),
		.M_AXI_AWQOS(m03_axi_awqos),
		.M_AXI_AWUSER(m03_axi_awuser),
		.M_AXI_AWVALID(m03_axi_awvalid),
		.M_AXI_AWREADY(m03_axi_awready),
		.M_AXI_WDATA(m03_axi_wdata),
		.M_AXI_WSTRB(m03_axi_wstrb),
		.M_AXI_WLAST(m03_axi_wlast),
		.M_AXI_WUSER(m03_axi_wuser),
		.M_AXI_WVALID(m03_axi_wvalid),
		.M_AXI_WREADY(m03_axi_wready),
		.M_AXI_BID(m03_axi_bid),
		.M_AXI_BRESP(m03_axi_bresp),
		.M_AXI_BUSER(m03_axi_buser),
		.M_AXI_BVALID(m03_axi_bvalid),
		.M_AXI_BREADY(m03_axi_bready),
		.M_AXI_ARID(m03_axi_arid),
		.M_AXI_ARADDR(m03_axi_araddr),
		.M_AXI_ARLEN(m03_axi_arlen),
		.M_AXI_ARSIZE(m03_axi_arsize),
		.M_AXI_ARBURST(m03_axi_arburst),
		.M_AXI_ARLOCK(m03_axi_arlock),
		.M_AXI_ARCACHE(m03_axi_arcache),
		.M_AXI_ARPROT(m03_axi_arprot),
		.M_AXI_ARQOS(m03_axi_arqos),
		.M_AXI_ARUSER(m03_axi_aruser),
		.M_AXI_ARVALID(m03_axi_arvalid),
		.M_AXI_ARREADY(m03_axi_arready),
		.M_AXI_RID(m03_axi_rid),
		.M_AXI_RDATA(m03_axi_rdata),
		.M_AXI_RRESP(m03_axi_rresp),
		.M_AXI_RLAST(m03_axi_rlast),
		.M_AXI_RUSER(m03_axi_ruser),
		.M_AXI_RVALID(m03_axi_rvalid),
		.M_AXI_RREADY(m03_axi_rready)
	);

// Instantiation of Axi Bus Interface S00_AXI
	phantom_dummy_4_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) phantom_dummy_4_v1_0_S00_AXI_inst (
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready)
	);

	// Add user logic here

	// User logic ends

	endmodule
