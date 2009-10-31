module Deproll

  module InstalledGems

    def self.scan(dir)
      puts "Scanning for installed gems on your system"
      puts "#{SystemGem.all.count} gems found"
    end

    class SystemGem
      def self.all

      end
    end


  end

end
