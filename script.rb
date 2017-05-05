#!ruby
# Historie Löschen
# Version 1.1 - 2017-05-05
# ralph.sluiters@vodafone.com
require 'date'
 
#2228 = MA Sven Eric Adolf
#4997 = MA Aydogan, Sibel
 
 
SCLEVELS = [
[ISPS::PlanContext::LEVEL_PLAN,"Plan"],
[ISPS::PlanContext::LEVEL_WISH,"Wunsch"],
[ISPS::PlanContext::LEVEL_ALTERNATIVE_WISH,"Ausweichwunsch"],
[ISPS::PlanContext::LEVEL_ABSENCE_WISH,"Abwesenheitswunsch"],
[ISPS::PlanContext::LEVEL_FINAL,"Aktueller Stand"],
[ISPS::PlanContext::LEVEL_TIME_RECORDING,"Zeiterfassung"],
[ISPS::PlanContext::LEVEL_ACD,"Externes System"],
[ISPS::PlanContext::LEVEL_AVAIL,"Verfügbarkeit"],
[ISPS::PlanContext::LEVEL_ONCALL,"Rufbereitschaft"],
[ISPS::PlanContext::LEVEL_CORRECTION,"Korrektur"],
[ISPS::PlanContext::LEVEL_VERSION1,"Backup Version 1"],
[ISPS::PlanContext::LEVEL_VERSION2,"Backup Version 2"],
[ISPS::PlanContext::LEVEL_VERSION3,"Backup Version 3"]]
 
 
 
class Date
 
    ############################################################################
    #
    #   Method Name:-   to_s
    #   Description:-   Convert a date to String.
    #   Parameters:-    None.
    #   Return Values:- String containing a localised Date.
    #
    ############################################################################
    def to_s
        case $ISPSLanguage
            when ISPS::LANG_GERMAN #German
                format('%02d.%02d.%04d', self.day, self.month, self.year)
            else
                format('%04d-%02d-%02d', self.year, self.month , self.day)
        end
    end #to_s
end #class Date
 
 
class Script
                RIGHT_ALIGN                   = {:style => 'text-align: right;'}
                LEFT_ALIGN                       = {:style => 'text-align: left;'}
 
  def datum(string)
    t,m,j = string.split(".") if string
 
    Date.new(j.to_i,m.to_i,t.to_i)
  rescue Exception => e
     Date.today + string.to_i
  end 
 
  def set_plancontext(from, to, levels)
    @planRep = ISPS::PlanRep.new
    @planRep.attach session
       # Create a new planContext.
     @planContext = ISPS::PlanContext.new @planRep
     @planContext.dateFrom = from
     @planContext.dateTo = to
     
      @planContext.level = levels
      @planContext.displayLevel = ISPS::PlanContext::DISPLAY_MINIMAL
      @planContext.defLayerMode = ISPS::PlanContext::LAYER_MODE_TOP
      @planContext.planUnitIds = @PlanUnitIds
      @planContext.staffIds  = @staffIds.slice(0,10)
      @planContext.write
  end
 
  def onStart
    session
    @from = datum(args["from"])
    @to = datum(args["to"])
 
    @PlanUnitIds = session.planUnits.map{|p| p.id}
    @staff = session.staffs
    @staffIds = []
    @levels = []
    if args["levels_multiple"]   
      @levels += args["levels_multiple"].split(":").map{|l| l.to_i}
    else
      @levels << args["levels"].to_i
    end
 
    @alle_ma = (args["alle_ma"] == "1")
 
    if @alle_ma
      @staffIds = @staff.map{|s| s.id}
    else
      if args["staffids_multiple"]   
        @staffIds += args["staffids_multiple"].split(":").map{|l| l.to_i}
      else
        @staffIds << args["staffids"].to_i
      end
    end
 
    @nur_historie = (args["nur_historie"] == "1")
  end #onStart
  
  
 
 
  def onView #generates the view
    puts bold "Alte Plandaten löschen"    
    print '<br/>'
 
    from = inp('from',@from)
    to = inp('to',@to)
    selLevel = sel("levels",true)
    SCLEVELS.each{|l| selLevel << option(l[0],l[1],@levels.include?(l[0])) }
    selStaff = sel("staffids",true)
    @staff.each{|s| selStaff << option(s.id,"#{s.id}: #{s.name}",@staffIds.include?(s.id)) }
 
    cbma = checkBox('alle_ma',"",@alle_ma)
    cb = checkBox('nur_historie',"",@nur_historie)
 
    fs = fieldset("Parameter")
    fs << ftable([LEFT_ALIGN,"Datum von:", RIGHT_ALIGN,from],
                [LEFT_ALIGN,"Datum bis:",RIGHT_ALIGN, to],
                [LEFT_ALIGN,"Level:",RIGHT_ALIGN,selLevel],
                [LEFT_ALIGN,"Alle Mitarbeiter:",RIGHT_ALIGN,cbma],
                [LEFT_ALIGN,"Mitarbeiter:",RIGHT_ALIGN,selStaff],
                [LEFT_ALIGN,"Nur Historie löschen:",RIGHT_ALIGN,cb])
    puts fs
 
 
    puts text "'OK' drücken um Löschen zu starten"   
  end #onView
  
  
  def onRun
   
   if @staffIds.size>300
      puts "Fehler! Max 300 Mitarbeiter auswählen"
    else
      set_plancontext(@from,@to,@levels)
      @levels.each do |level|
        puts "Lösche Level #{level} von #{@from} bis #{@to} für die MA #{@staffIds.join(",")} #{@nur_historie ? "OHNE" : "MIT"} aktuellen Plan"
        @planContext.emptyTopLayer(level, @from,@to,@staffIds) unless @nur_historie     
        @planContext.deleteEvolution(@from,@to,level,@staffIds)
      end
   
      puts "Done!"
    end
  end #onRun
  
end #class Script