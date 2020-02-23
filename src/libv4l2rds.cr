require "./linux/videodev2"

@[Link("v4l2rds")]
lib LibV4L2RDS
  V4L2_RDS_VERSION = 2

  MAX_ODA_CNT = 18
  MAX_AF_CNT = 25
  MAX_TMC_ADDITIONAL = 28
  MAX_TMC_ALT_STATIONS = 32
  MAX_TMC_AF_CNT = 4
  MAX_EON_CNT = 20

  V4L2_RDS_PI         = 0x01    # Program Identification
  V4L2_RDS_PTY        = 0x02    # Program Type
  V4L2_RDS_TP         = 0x04    # Traffic Program
  V4L2_RDS_PS         = 0x08    # Program Service Name
  V4L2_RDS_TA         = 0x10    # Traffic Announcement
  V4L2_RDS_DI         = 0x20    # Decoder Information
  V4L2_RDS_MS         = 0x40    # Music / Speech flag
  V4L2_RDS_PTYN       = 0x80    # Program Type Name
  V4L2_RDS_RT         = 0x100   # Radio-Text
  V4L2_RDS_TIME       = 0x200   # Date and Time information
  V4L2_RDS_TMC        = 0x400   # TMC availability
  V4L2_RDS_AF         = 0x800   # AF (alternative freq) available
  V4L2_RDS_ECC        = 0x1000  # Extended County Code
  V4L2_RDS_LC         = 0x2000  # Language Code
  V4L2_RDS_TMC_SG     = 0x4000  # RDS-TMC single group
  V4L2_RDS_TMC_MG     = 0x8000  # RDS-TMC multi group
  V4L2_RDS_TMC_SYS    = 0x10000 # RDS-TMC system information
  V4L2_RDS_EON        = 0x20000 # Enhanced Other Network Info
  V4L2_RDS_LSF        = 0x40000 # Linkage information
  V4L2_RDS_TMC_TUNING = 0x80000 # RDS-TMC tuning information

  V4L2_RDS_GROUP_NEW = 0x01 # New group received
  V4L2_RDS_ODA       = 0x02 # Open Data Group announced

  V4L2_RDS_FLAG_STEREO          = 0x01
  V4L2_RDS_FLAG_ARTIFICIAL_HEAD = 0x02
  V4L2_RDS_FLAG_COMPRESSED      = 0x04
  V4L2_RDS_FLAG_DYNAMIC_PTY     = 0x08

  V4L2_TMC_TUNING_INFO  = 0x10    # Bit 4 indicates Tuning Info / User msg
  V4L2_TMC_SINGLE_GROUP = 0x08    # Bit 3 indicates Single / Multi-group msg

  alias Char = LibC::Char
 
  # struct to encapsulate one complete RDS group
  struct V4L2RDSGroup
    p1 : UInt16          # Program Identification
    group_version : Char # group version ('A' / 'B')
    group_id : UInt8     # group number (0..16)

    # uninterpreted data blocks for decoding (e.g. ODA)
    data_b_lsb : UInt8
    data_c_msb : UInt8
    data_c_lsb : UInt8
    data_d_msb : UInt8
    data_d_lsb : UInt8
  end

  # struct to encapsulate some statistical information about the decoding process
  struct V4L2RDSStatistics
    block_cnt : UInt32       # total amount of received blocks
    group_cnt : UInt32       # total amount of successfully decoded groups

    block_error_cnt : UInt32 # blocks that were marked as erroneous and had to
                             # be dropped

    group_error_cnt : UInt32 # group decoding processes that had to be aborted
                             # because of erroneous blocks or wrong order of
                             # blocks

    block_corrected_cnt : UInt32 # blocks that contained 1-bit errors which
                                 # were corrected

    group_type_cnt : UInt32[16] # number of occurrence for each defined RDS
                                # group
  end

  # struct to encapsulate the definition of one ODA (Open Data Application) type
  struct V4L2RDSODA
    group_id : UInt8     # RDS group used to broadcast this ODA
    group_version : Char # group version (A / B) for this ODA
    aid : UInt16         # Application Identification for this ODA,
                         # AIDs are centrally administered by the
                         # RDS Registration Office (rds.org.uk)
  end

  struct V4L2RDSODASet
    size : UInt8 # size of the set (might be smaller
                 # than the announced size)

    announced_af : UInt8    # number of announced AF
    af : UInt8[MAX_AF_CNT]  # AFs defined in Hz
  end

  struct V4L2RDSAFSet
    size : UInt8            # size of the set (might be smaller than the
                            # announced size)
    announced_af : UInt8    # number of announced AF
    af : UInt32[MAX_AF_CNT] # AFs defined in Hz
  end

  # struct to encapsulate one entry in the EON table (Enhanced Other Network)
  struct V4L2RDSEon
    valid_fields : UInt32
    pi : UInt16
    ps : StaticArray(UInt8, 9)
    pty : UInt8
    ta, tp : Bool
    lsf : UInt16 # Linkage Set Number
    af : V4L2RDSAFSet
  end

  # struct to encapsulate a table of EON information
  struct V4L2RDSEonSet
    size : UInt8  # size of the table
    index : UInt8 # current position in the table
    eon : V4L2RDSEon[MAX_EON_CNT]
  end

  # struct to encapsulate alternative frequencies (AFs) for RDS-TMC stations.
  struct V4L2TMCAltFreq
    af_size : UInt8                           # number of known AFs
    af_index : UInt8
    mapped_af_size : UInt8                    # number of mapped AFs
    mapped_af_index : UInt8
    af : UInt32[MAX_TMC_AF_CNT]               # AFs defined in Hz
    mapped_af : UInt32[MAX_TMC_AF_CNT]        # mapped AFs defined in Hz
    mapped_af_tuning : UInt32[MAX_TMC_AF_CNT] # mapped AFs defined in Hz
  end

  # struct to encapsulate information about stations carrying RDS-TMC services
  struct V4L2TMCStation
    pi : UInt16
    ltn : UInt8 # database-ID of ON
    msg : UInt8 # msg parameters of ON
    sid : UInt8 # service-ID of ON
    afi : V4L2TMCAltFreq
  end

  # struct to encapsulate tuning information for TMC
  struct V4L2TMCTuning
    station_cnt : UInt8 # number of announced alternative stations
    index : UInt8
    station : V4L2TMCStation[MAX_TMC_ALT_STATIONS] # information about other
                                                   # stations carrying the same
                                                   # RDS-TMC service
  end

  # struct to encapsulate an additional data field in a TMC message
  struct V4L2TMCAdditional
    label : UInt8
    data : UInt16
  end

  # struct to encapsulate an arbitrary number of additional data fields
  struct V4L2TMCAdditionalSet
    size : UInt8
    fields : V4L2TMCAdditional[MAX_TMC_ADDITIONAL]
  end

  struct V4L2RDSTMCMsg
    length : UInt8 # length of multi-group message (0..4)
    sid : UInt8    # service identifier at time of reception
    extend : UInt8
    dp : UInt8     # duration and persistence
    event : UInt16 # TMC event code
    location : UInt16 # TMC event location
    follow_diversion : Bool # indicates if the driver is adviced to follow the diversion
    neg_direction : Bool # indicates negative / positive direction

    additional : V4L2TMCAdditionalSet # decoded additional information
                                      # (only available in multi-group message)
  end

  # struct to encapsulate all TMC related information, including TMC System
  struct V4L2RDSTMC
    ltn : UInt8 # location_table_number
    afi : Bool # alternative frequency indicator
    enhanced_mode : Bool # mode of transmission,
                         # if false -> basic => gaps between tmc groups
                         #                      gap defines timing behavior
                         # if true -> enhanced => t_a, t_w and t_d define
                         #                        timing behavior of tmc groups
    mgs : UInt8 # message geographical scope
    sid : UInt8 # service identifier (unique ID on national level)
    gap : UInt8 # Gap parameters
    t_a : UInt8 # activity time (only if mode = enhanced)
    t_w : UInt8 # window time (only if mode = enhanced
    t_d : UInt8 # delay time (only if mode = enhanced
    spn : UInt8[9] # service provider name

    tmc_msg : V4L2RDSTMCMsg

    tuning : V4L2TMCTuning
  end

  # struct to encapsulate state and RDS information for current decoding process
  struct V4L2RDS
    #
    # state information
    #

    decode_information : UInt32 # state of decoding process
    valid_fields : UInt32       # currently valid info fields of this structure

    #
    # RDS info fields
    #

    is_rbds : Bool      # use RBDS standard version of LUTs
    pi : UInt16         # Program Identification
    ps : UInt8[9]       # Program Service Name, UTF-8 encoding, '\0' terminated
    pty : UInt8         # Program Type
    ptyn : UInt8[9]     # Program Type Name, UTF-8 encoding, '\0' terminated
    ptyn_ab_flag : Bool # PTYN A/B flag (toggled), to signal change of PTYN
    rt_length : UInt8   # length of RT string
    rt : UInt8[65]      # Radio-Text string, UTF-8 encoding, '\0' terminated
    rt_ab_flag : Bool   # RT A/B flag (toggled), to signal transmission of new
                        # RT

    ta : Bool          # Traffic Announcement
    tp : Bool          # Traffic Program
    ms : Bool          # Music / Speech flag
    di : UInt8         # Decoder Information
    ecc : UInt8        # Extended Country Code
    lc : UInt8         # Language Code
    time : LibC::TimeT # local time and date of transmission

    rds_statistics : V4L2RDSStatistics
    rds_oda : V4L2RDSODASet # Open Data Services
    rds_af : V4L2RDSAFSet   # Alternative Frequencies
    rds_eon : V4L2RDSEonSet # EON information
    tmc : V4L2RDSTMC        # TMC information
  end

  fun v4l2_rds_create(is_rbds : Bool) : V4L2RDS *
  fun v4l2_rds_destroy(handle : V4L2RDS *)
  fun v4l2_rds_reset(handle : V4L2RDS *, reset_statistics : Bool)

  # Note: defined in linux/videodev2.h
  struct V4L2RDSData
    lsb, msb, block : UInt8
  end
  fun v4l2_rds_add(handle : V4L2RDS *, rds_data : V4L2RDSData *) : UInt32

  #
  # group of functions to translate numerical RDS data into strings
  #
  {% for field in [:pty, :language, :country, :coverage] %}
  fun v4l2_rds_get_{{ field.id }}_str(handle : V4L2RDS) : Char *
  {% end %}

  fun v4l_rds_get_group(handle : V4L2RDS) : V4L2RDSGroup *
end
