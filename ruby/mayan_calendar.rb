require 'date'

# MayanDate
#  + Unit
#  + Origin
#  + Date
#    + date
#    + long_count
#    + tzolkin
#    + haab
#  + LongCount
#  + Tzolkin
#  + Haab

module MayanUnit
  PIKTUN = 20
  BAKTUN = 13
  KATUN  = 20
  TUN    = 20
  WINAL  = 18
  KIN    = 20
  C_PIKTUN = BAKTUN*KATUN*TUN*WINAL*KIN
  C_BAKTUN = KATUN*TUN*WINAL*KIN
  C_KATUN  = TUN*WINAL*KIN
  C_TUN    = WINAL*KIN
  C_WINAL  = KIN
  COEFFICIENTS = [C_PIKTUN,C_BAKTUN,C_KATUN,C_TUN,C_WINAL,1]
  ALL = [PIKTUN,BAKTUN,KATUN,TUN,WINAL,KIN]
end

class MayanCalendar
  include MayanUnit

  def self.gmt_584285 # 8/13開始
  end
  def self.gmt_584283 # 8/11開始
  end

  class MayanDate
    attr_accessor :date, :long_count, :tzolkin, :haab
    def self.create_by_date(date)
      obj = new
      obj.date = date
      obj.long_count = LongCount.to_long_count(date: date)
      obj.tzolkin    = Tzolkin.new(date: date)
      obj.haab       = Haab.new(date: date)
      obj
    end
    def self.create_by_long_count(long_count_arr)
      # long_count_arr
      #   piktun,baktun,katun,tun,winal,kin
      # piktunが設定されていない場合は0piktunとして扱う
      long_count_arr = [0] + long_count_arr if long_count_arr.size == 5
      obj = new
      obj.long_count = LongCount.new(*long_count_arr)
      obj.date = obj.long_count.date
      obj.tzolkin = Tzolkin.new(date: obj.long_count.date)
      obj.haab = Haab.new(date: obj.long_count.date)
      obj
    end
    def to_s
      "#{long_count.to_s} #{tzolkin.to_s} / #{haab.to_s}"
    end
    # Calculate Posterior Distance Number
    def iuti(lc_reverse_array)
      kin,winal,tun,katun,baktun,piktun = lc_reverse_array
      lc_piktun = piktun || 0
      lc_baktun = baktun || 0
      lc_katun  = katun || 0
      lc_tun    = tun || 0
      lc_winal  = winal || 0
      lc_kin    = kin || 0
      new_lc = @long_count.reorganize(true, lc_piktun, lc_baktun, lc_katun, lc_tun, lc_winal, lc_kin)
      self.class.create_by_long_count([
        new_lc.piktun, new_lc.baktun, new_lc.katun, new_lc.tun, new_lc.winal, new_lc.kin ])
    end
    # Calculate Anterior Distance Number
    def utiiy(lc_reverse_array)
      kin,winal,tun,katun,baktun,piktun = lc_reverse_array
      lc_piktun = piktun || 0
      lc_baktun = baktun || 0
      lc_katun  = katun || 0
      lc_tun    = tun || 0
      lc_winal  = winal || 0
      lc_kin    = kin || 0
      new_lc = @long_count.reorganize(false, lc_piktun, lc_baktun, lc_katun, lc_tun, lc_winal, lc_kin)
      self.class.create_by_long_count([
        new_lc.piktun, new_lc.baktun, new_lc.katun, new_lc.tun, new_lc.winal, new_lc.kin ])
    end
    private
    def initlalize; end
  end
end

module MayanOrigin
  GMT_584285 = [-3113,9,8]
  GMT_584283 = [-3113,9,6]
  ORIGIN_J_GMT_584285 = Date.new(*GMT_584285)
  ORIGIN_G_GMT_584285 = ORIGIN_J_GMT_584285.gregorian
  ORIGIN_J_GMT_584283 = Date.new(*GMT_584283)
  ORIGIN_G_GMT_584283 = ORIGIN_J_GMT_584283.gregorian
end

class LongCount
  attr_accessor :date, :piktun, :baktun, :katun, :tun, :winal, :kin
  include MayanUnit
  include MayanOrigin

  def initialize(piktun, baktun, katun, tun, winal, kin)
    @piktun, @baktun, @katun, @tun, @winal, @kin = piktun, baktun, katun, tun, winal, kin
    @date = ORIGIN_J_GMT_584283 +
      @piktun * C_PIKTUN + @baktun * C_BAKTUN + @katun * C_KATUN +
      @tun * C_TUN + @winal * C_WINAL + @kin
  end
  def baktun
    @baktun == 0 ? 13 : @baktun
  end
  def to_s(format: :default)
    [piktun, baktun, katun, tun, winal, kin].join('.') if format == :include_piktun
    [baktun, katun, tun, winal, kin].join('.')
  end
	def reorganize(plus_or_minus, piktun, baktun, katun, tun, winal, kin)
		ttl = piktun * C_PIKTUN + baktun * C_BAKTUN + katun * C_KATUN +
					tun * C_TUN + winal * C_WINAL + kin
		if plus_or_minus
			self.class.to_long_count(date: @date + ttl)
		else
			self.class.to_long_count(date: @date - ttl)
		end
	end
  def self.to_long_count(date: Date.today)
    base_julian = (date - ORIGIN_J_GMT_584283).to_i
    arr = []
    COEFFICIENTS.inject(base_julian){|a,e| arr << (a/e); a - (e*(a/e)) }
    new(*arr)
  end
end

class Tzolkin
  include MayanOrigin
  DAY_SIGNS = %w(Imix I'k Ak'bal Kan Chickchan Kimi Manik' Lamat Muluk Ok Chuwen Eb Ben Ix Men Kib Kaban Etz'nab Kawak Ajaw)
  COEFFICIENT_COUNT = 13
  def initialize(date: Date.today)
    return unless date
    base_julian = (date - ORIGIN_J_GMT_584283).to_i
    coefficient_base = base_julian + 4 # 4は補正
    @coefficient = coefficient_base % COEFFICIENT_COUNT
    day_sign_base = base_julian + 19 # 19は補正
    @day_sign = DAY_SIGNS[day_sign_base % DAY_SIGNS.size]
  end
  def to_s(format: :default)
    "#{@coefficient}-#{@day_sign}"
  end
end

class Haab
  include MayanOrigin
  class HaabDate
    def initialize(month_sign, day_count)
      @month_sign, @day_count = month_sign, day_count
    end
    def to_s
      "#{@day_count}-#{@month_sign}"
    end
  end
  TOTAL_DAY_COUNT = 365
  DAY_COUNT = (1..20).to_a
  WAYEB_DAY_COUNT = (1..5).to_a
  MONTH_SIGNS_1 = %w(Pop Wo Sip Sots Sek Xul Yaxk'in Mol Che'n Yax Sak Keh Mak K'ank'in Muwan Pax K'ayab Kumk'u)
  MONTH_SIGNS_2 = %w(Wayeb)
  DAYS = MONTH_SIGNS_1.map{|m| DAY_COUNT.map{|d| HaabDate.new(m,d) }}.flatten +
         MONTH_SIGNS_2.map{|m| WAYEB_DAY_COUNT.map{|d| HaabDate.new(m,d) }}.flatten
  def initialize(date: Date.today)
    base_julian = (date - ORIGIN_J_GMT_584283).to_i
    @haab_date = DAYS[(base_julian + 347) % TOTAL_DAY_COUNT] # 347は補正
  end
  def to_s
    @haab_date.to_s
  end
end
