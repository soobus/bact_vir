#Valery Nemychnikova

#require_relative 'graphics.rb'
class Game
#взаимодействие элементов игры друг с другом
  attr_accessor :world, :timer
  
  def initialize cols, rows, bact_coords = [], viruses_coords= [] #bact_coords, viruses_coords -- двумерные массивы
    @world = World.new(cols, rows) #создание нового мира
    bact_coords.each do |xy| x = xy[0]; y = xy[1]; @world.get_cell(x, y).to_bact!; end #введение бактерий в мир
    viruses_coords.each do |xy| x = xy[0]; y = xy[1]; @world.get_cell(x, y).to_virus!; end #введение вирусов в мир
    @timer = 0 #отсчет прошедших ходов
    @finish = false
    @random_numbers = []
  end

  def random; @world.random; end

  def generate_random_number; @world.generate_0_1; end
  def puts_world; puts @world.field; end      
  def puts_viruses_coords; @world.field.each do |line| line.each do |cell| print "[#{cell.x},#{cell.y}] \n" if cell.is_virus? end end; end
  def puts_bact_coords; @world.field.each do |line| line.each do |cell| print "[#{cell.x},#{cell.y}] \n" if cell.is_bact? end end; end
 
  
  def play
   # 10.times do
    until @finish or @timer == 100
      for i in 0...@world.cols
        print '['
        for j in 0...@world.rows
          if @world.get_cell(i, j).is_bact?
            print 0
          elsif @world.get_cell(i, j).is_virus?
            print 'X'
          else
            print ' '
          end
        end
        puts ']'
      end

      puts " "

      update_position
      
      @random_numbers << self.generate_random_number

    end

    puts "Finished, code 0, timer: #{@timer}"
    print "random:", @random_numbers
    puts "middle = #{@random_numbers.inject('+').to_f/100}"

  end
 
  def update_position

    #массивы для сбора клеток, переходящих в другое состояние на этом ходу, хэш для сбора телепортирующихся вирусов
    @to_bact = []
    @to_virus = []
    @kill = []
    @teleport = {}
    @bact_eater = []

    #обход поля
    @world.field.each do |line| line.each do |cell|
      cell.get_cells_around(@world)
      use_rules(cell)
    end
    end

    #переход в другое состояние
    @to_bact.each do |xy| x = xy[0]; y = xy[1]; @world.get_cell(x, y).to_bact! end
    @to_virus.each do |xy| x = xy[0]; y = xy[1]; @world.get_cell(x, y).to_virus! end
    @kill.each do |xy| x = xy[0]; y = xy[1]; @world.get_cell(x, y).kill! end
    @teleport.each do |prev_coord, cur_coord|
                              x0 = prev_coord[0]; y0 = prev_coord[1]
                              x = cur_coord[0]; y = cur_coord[1]
                              @world.get_cell(x0, y0).kill!
                              @world.get_cell(x, y).to_virus!
    end
    @bact_eater.each do |xy| x = xy[0]; y = xy[1]; @world.get_cell(x, y).to_virus! end

    @finish = true if @kill.size == 0 && @to_bact.size == 0
    @timer+=1
  end 

 
  ######==============ПРАВИЛА ИГРЫ======================================
  #1. в пустой клетке, рядом с которой есть 3 бактерии, рождается бактерия
  #2. бактерия продолжает жить, только если у нее рядом 2 или 3 бактерии
  #3. вирус без соседей-бактерий телепортируется в случайную пустую клетку в окрестности Мура
  #4. вирус с соседями-бактериями (0<бактерии<3) телепортируется в случайную бактерию
  #5. вирус с >2 соседей-бактерий погибает
 
  private

  def use_rules cell
    
    #Правило 1: в пустой клетке, рядом с которой есть 3 бактерии, рождается бактерия
    if cell.is_dead?
    @to_bact << [cell.x, cell.y] if cell.num_of_bact_around == 3 
    end

    #Правило 2: бактерия продолжает жить, только если рядом 2 или 3 бактерии
    if cell.is_bact?
    @kill << [cell.x, cell.y] if not [2, 3].include?(cell.num_of_bact_around)
    end

    #Правило 3: вирус без соседей-бактерий телепортируется в случайную незанятую клетку в окрестности Мура
    if cell.is_virus? && cell.num_of_bact_around==0
    @teleport[[cell.x, cell.y]] = cell.empty_cells_coords_around.sample   
    end

    #Правило 4: вирус с соседями-бактериями телепортируется в случайную бактерию
    if cell.is_virus? && (cell.num_of_bact_around>0 && cell.num_of_bact_around<=3)
    @bact_eater << cell.bact_coords_around.sample
    end

    #Правило 5: вирус с больше, чем 2 соседями-бактериями, гибнет
    if cell.is_virus? && cell.num_of_bact_around > 1
    @kill << [cell.x, cell.y]
    end

  end  
  
end

class Cell
#хранение информации о состоянии, типе и поведении клетки
  attr_accessor :x, :y, :type
  
  def initialize(x = 0, y = 0, type = :dead)
    @x = x
    @y = y
    @type = type # :dead, :virus, :bact
    @cells_around = []
  end
#методы переходов между типами клетки
  def kill!; @type = :dead; end
  def to_bact!; @type = :bact; end
  def to_virus!; @type = :virus; end

#методы проверки типов клетки
  def is_dead?; @type == :dead ? true : false; end
  def is_bact?; @type == :bact ? true : false; end
  def is_virus?; @type == :virus ? true : false; end

#получение соседей
  def get_cells_around world
    @cells_around = []
        @cells_around << world.field[@x - 1][@y] #снизу
        @cells_around << (@x == world.rows-1 ? world.field[0][@y] : world.field[@x + 1][@y]) #сверху
        @cells_around << (@y == world.cols-1 ? world.field[@x][0] : world.field[@x][@y + 1]) #справа
        @cells_around << world.field[@x][@y - 1] #слева
        @cells_around << (@y == world.cols-1 ? world.field[@x - 1][0] : world.field[@x - 1][@y + 1]) #снизу справа
        @cells_around << world.field[@x - 1][@y - 1] #снизу слева
        @cells_around << (@x == world.rows-1 ? (@y == world.cols-1 ? world.field[0][0] : world.field[0][@y+1]) : (@y == world.cols-1 ? world.field[@x + 1][0] : world.field[@x + 1][@y+1])) #сверху справа
        @cells_around << (@x == world.rows-1 ? world.field[0][@y - 1] : world.field[@x + 1][@y - 1]) #сверху слева
    @cells_around
  end
  
  def get_0_1
    if @type == :bact
      return 1
    else
      return 0
    end
  end

  def num_of_bact_around
    number = 0
    @cells_around.each do |cell| number+=1 if cell.is_bact? end
    number
  end

  def num_of_viruses_around
    number = 0
    @cells_around.each do |cell| number+=1 if cell.is_virus? end
    number
  end
  
  def bact_coords_around
    coords = []
    @cells_around.each do |cell| coords << [cell.x, cell.y] if cell.is_bact? end
    coords
  end

  def empty_cells_coords_around
    coords = []
    @cells_around.each do |cell| coords << [cell.x, cell.y] if cell.is_dead? end
    coords
  end
end

class World
#хранение и изменение игрового мира
  attr_accessor :cols, :rows, :field, :empty

  def initialize(cols = 10, rows = 10)
    @cols = cols
    @rows = rows
    @field = Array.new(rows){ |row| Array.new(cols){ |col| Cell.new(row, col) }}
    @empty = true
  end

  def get_cell(x, y); @field[x][y]; end
  
  def generate_0_1
    a = 0
    @field.each do |row| row.each do |cell|
        a ^= cell.get_0_1
      end
    end
    return a
    #a = @field[0][0].get_0_1
    #b = @field[24][25].get_0_1
    #c = @field[37][48].get_0_1
    #return a ^ b ^ c ^ 0 
  end

  def random
    @field.each do |row| row.each do |cell|
      random = rand
     #   if rand < 1.to_f/3 && rand > 0
     #     puts "random: #{rand}, to_bact!"
     #     cell.to_bact!
     #   elsif rand < 2.to_f/3 && rand > 1.to_f/3
     #     puts "random: #{rand}, to_virus!"
     #     cell.to_virus!
     #   else
     #     cell.kill!
     #   end
      
      if rand < 0.5
        cell.to_bact!
      end
        
      end
    end
  end
end

##################################
puts 'Write field size, x y'
size = gets.chomp
cols = size.split(" ")[0].to_i
rows = size.split(" ")[1].to_i
=begin
puts 'Want to read bact file? Y/N'
if gets.chomp == 'N'
  puts 'Write number of bacts'
  numbact = gets.chomp.to_i
  puts 'Write coords in format 10 9'
  bacteria = Array.new(numbact) { get = gets.chomp
     x = get.split(" ")[0].to_i
     y = get.split(" ")[1].to_i
     x%=cols if x >= cols.to_i
     y%=rows if y >= rows.to_i
     [x, y]  }
else
  puts 'Write the name of a figure. [glider, ...]'
  name = gets.chomp
  numbact = File.read("#{name}.txt").split("\n")[0].to_i
  puts numbact
  bacteria = Array.new(numbact) { |i| get = File.read("#{name}.txt").split("\n")[i+1]
     x = get.split(" ")[0].to_i
     y = get.split(" ")[1].to_i
     x%=cols if x >= cols.to_i
     y%=rows if y >= rows.to_i
     [x, y]  }
end
puts 'Write number of viruses'
numvir = gets.chomp.to_i
puts 'Write coords in format 10 9'
viruses = Array.new(numvir) { get = gets.chomp
   x = get.split(" ")[0].to_i
   y = get.split(" ")[1].to_i
   x%=cols if x >= cols.to_i
   y%=rows if y >= rows.to_i
   [x, y]  }

game = Game.new(size.split(" ")[0].to_i, size.split(" ")[1].to_i, bacteria,  viruses)
=end
game = Game.new(size.split(" ")[0].to_i, size.split(" ")[1].to_i)
game.random

game.play

#window = GameWindow.new(game)
#window.show
