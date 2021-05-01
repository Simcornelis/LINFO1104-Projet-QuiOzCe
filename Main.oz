functor
import
  Application Browser Open OS ProjectLib System
define
  CWD = {Atom.toString {OS.getCWD}}#"/"
  Browse = proc {$ Buf} {Browser.browse Buf} end
  Print = proc {$ S} {System.print S} end
  File = {New Open.file init(name:'stdout' flags: [write create truncate text])}
  FPrint = proc {$ S} {File write(vs:S)} end
  Args = {Application.getArgs record(
          'nogui'(single type:bool default:false optional:true)
          'db'(single type:string default:CWD#"database.txt")
          'ans'(single type:string default:CWD#"test_answers.txt" optional:true))}
in
  local
    NoGUI = Args.'nogui'
    ListOfCharacters = {ProjectLib.loadDatabase file Args.'db'}
    ListOfAnswers = {ProjectLib.loadCharacter file Args.'ans'}

    % get next best question to ask to split possible anwers equally
    fun {NextQuestion Data}
      % returns score(q1:0 q2:0 ... qn:0) (each question starts with a 0 score)
      Start = {List.toRecord score {List.map {Arity Data.1}.2 fun {$ E} E#0 end}}

      % returns a record with the score set for each question like score(q1:2 q2:5 q3:1)
      fun {ScoreQuestions Acc Elem}
        {Record.mapInd Acc fun {$ Q E} if Elem.Q then E+1 else E end end}
      end

      % returns the question with the best score
      fun {GetBestScoredQ Scores Persons}
        Ideal = Persons div 2
        fun {Dist A} {Abs Ideal - A} end
        fun {IsBetterThan Q Acc B}
          if {Dist Acc.2} > {Dist B} then Q#B else Acc end
        end
      in
        {Record.foldLInd Scores IsBetterThan nil#Persons+1}.1 % Acc = Question#Score
      end

      Scores = {FoldL Data ScoreQuestions Start}

      % true if all players left have the same answers (then you shouldn't ask the questions)
      AllEqual = {Record.all Scores fun {$ E} E == {Length Data} orelse E == 0 end}
    in
      if {Length Data} =< 1 orelse {Width Data.1} =< 1 orelse AllEqual then nil
      else {GetBestScoredQ Scores {Length Data}}
      end
    end

    fun {TreeBuilder Data}
      % splits a list in true and false for the question (with the question removed)
      fun {Split Data Question}
        T F Ask RemoveQ
      in
        Ask = fun {$ E} E.Question end
        {List.partition Data Ask T F} % split true (in T) and false (in F) results to Ask
        RemoveQ = fun {$ E} {Record.subtract E Question} end % remove question from db records
        question(Question
                true:{TreeBuilder {Map T RemoveQ}}
                false:{TreeBuilder {Map F RemoveQ}}
                unknown:{TreeBuilder {Map Data RemoveQ}})
      end
    in
      if Data == nil then nil
      else
        case {NextQuestion Data}
          of nil then {Map Data fun {$ E} E.1 end} % keep only persons list or nil (if none)
          [] NextQ then {Split Data NextQ}
        end
      end
    end

    fun {GameDriver Tree}
      fun {Next Tree Last}
        case Tree
          of nil then {ProjectLib.surrender}
          [] question(Q true:T false:F unknown:U) then
            case {ProjectLib.askQuestion Q}
              of oops then
                case Last of H|T then {Next H T} else {Next Last Last} end
              [] true then {Next T Tree|Last}
              [] false then {Next F Tree|Last}
              [] unknown then {Next U Tree|Last}
            end
          [] List then {ProjectLib.found List}
        end
      end
    in
      % {Browse Tree}
      
      case {Next Tree Tree}
        of false then {Print {ProjectLib.surrender}}
        [] H|T then {FPrint {List.foldL T fun {$ A B} A#","#B end H}}
        [] Result then {FPrint Result}
      end
      
      if NoGUI == false then {FPrint '\n'} end

      unit % always return unit
    end
  in
    {ProjectLib.play opts(characters:ListOfCharacters autoPlay:ListOfAnswers
                          noGUI:NoGUI builder:TreeBuilder driver:GameDriver
                          oopsButton:true allowUnknown:true)}
    {File close}
    {Application.exit 0}
  end
end
