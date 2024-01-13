module Wga
  # Make it possible to format output text
  class Formatter

    UNITS = [:paragraph, :section, :text, :bold, :code, :table, :formatter]

    def initialize(units = nil)
      @units = units || Array.new
      @current_section = nil
    end

    def +(other)
      self.class.new(@units + other.units)
    end

    def empty?
      @units.empty?
    end

    # Otput format for console
    def to_console
      out = ""
      @units.each do |unit|
        next unless unit[1]
        unit_str = case unit.first
        when :paragraph
          "####### #{unit[1].upcase} ########{$/}".light_red
        when :section
          "===== #{unit[1]} =====#{$/}".bold
        when :text
          unit[1].chomp + $/
        when :bold
          "#{unit[1].chomp}#{$/}".bold
        when :code
          unit[1].chomp + $/
        when :table
          unit[1].chomp + $/
        when :formatter
          unit[1].is_a?(self.class) ? unit[1].to_console : unit[1].to_s.chomp + $/
        else
          unit[1]
        end
        out << unit_str if unit_str
      end
      out
    end

    # Otput format for JIRA
    def to_jira
      out = ""
      @units.each do |unit|
        unit_str = case unit[0]
        when :paragraph
          "h5. ####### #{unit[1].upcase} ########{$/}"
        when :section
          @current_section = unit[1]
          ''
        when :text
          @current_section ? ("h6. #{unit[1]}#{$/}" + unit[1].chomp + $/) : (unit[1].chomp + $/)
        when :bold
          "*#{unit[1]}*"
        when :code
          string = "{noformat#{(':title=' + @current_section) if @current_section}}" + $/ + unit[1] + "{noformat}" + $/
          @current_section = nil
          string
        when :table
          
        when :formatter
          unit[1].is_a?(self.class) ? unit[1].to_jira : unit[1].to_s.chomp + $/
        else
          unit[1]
        end
        out << unit_str
      end
      out
    end

    def to_s
      @units.reduce('') { |memo, unit| memo += unit[1].to_s.chomp + $/ }.chomp
    end

    def to_a
      @units.map { |unit| unit[1] }
    end

    # Catch calls of methods with unit's names
    def method_missing(unit, *args)
      if UNITS.include? unit
        content = args[0]
        @units << [unit, content] if content
        @units << [unit, yield] if block_given?
      else
        unit = unit.to_s.chomp('s').to_sym
        if UNITS.include? unit
          @units.map{ |u| u.first == unit ? u[1] : nil }.compact
        else
          super
        end
      end
    end

    def units
      @units
    end

  end
end