require 'rubygems'
require 'hpricot'

  
class MigrationGenerator
  
  def initialize(table_name, filename, timestamps = false)
    @table_name = table_name.to_sym
    @doc        = open(filename) { |f| Hpricot(f) }
    @timestamps = timestamps
    @elements   = []
    @line       = {}
  end
  
  def to_s(table_reference = "t")
    output = "create table #{@table_name} do |#{table_reference}| \n"
    output += generate_table_fields(table_reference)
    output += "\nend"
    output
  end
  
protected
  def each_table_row
    (@doc/"tbody/tr/td").each do |tr|
      yield tr
    end
  end
  
  def generate_table_fields(table_reference)
    index = 1
    
    each_table_row do |tr|
      generate_migration_line(index, tr)
      index += 1
      
      if index > 9
        index = 1
        add_line_to_elements
        clear_line
      end
    end
    
    elements(table_reference)
  end
  
  def generate_migration_line(index, tr)
    option = case index
      when 1; "field"
      when 3; "fk"
      when 4; "unique"
      when 5; "type"
      when 6; "size"
      when 7; "null"
      when 8; "default"
    end
    
    if option == "field"
      @line.merge!({ option => (tr/"strong").inner_html })
    else
      @line.merge!({ option => tr.inner_html })
    end
  end
  
private
  def elements(table_reference)
    t = table_reference
    output = ""
    
    @elements.each do |element|
      unless element["field"] == "id"
        output += "  #{t}.#{element["type"]} :#{element["field"]}"
        output += ", :null => #{element["null"].downcase}"
        output += ", :limit => #{element["size"]}" if element["size"].to_i > 0
        output += ", :default => #{element["default"]}" if element["default"] != "-"
        output += "\n" 
      end
    end
    
    output += "  #{t}.timestamps" if @timestamps
    output
  end

  def add_line_to_elements
    @elements << @line
  end

  def line=(value)
    @line.merge!(value)
  end

  def clear_line
    @line = {}
  end

  def timestamps
    @timestamps
  end
end

puts MigrationGenerator.new("matias", "example2.html")
