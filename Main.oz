functor
import
  ProjectLib
  Browser
  OS
  Open
  System
  Application
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
    DB = Args.'db'
    NoGUI = Args.'nogui'
    ListOfAnswersFile = Args.'ans'
    ListOfCharacters = {ProjectLib.loadDatabase file DB}
    ListOfAnswers = {ProjectLib.loadCharacter file ListOfAnswersFile}

    % get next best question to ask to split possible anwers equally
    fun {NextQuestion Data}
      % returns score(q1:0 q2:0 ... qn:0) (each question starts with a 0 score)
      Start = {List.toRecord score {List.map {Arity Data.1}.2 fun {$ E} E#0 end}}

      % returns a record with the score set for each question like score(q1:2 q2:5 q3:1)
      fun {ScoreQuestions Acc Elem}
        fun {BoolToInt B} if B then 1 else 0 end end
      in
        {Record.mapInd Acc fun {$ Q E} E + {BoolToInt Elem.Q} end}
      end

      % returns the question with the best score
      fun {GetBestScoredQ Scores Persons}
        Ideal = {Ceil {IntToFloat Persons} / 2.0}
        fun {Dist A} {Abs Ideal - {IntToFloat A}} end
        fun {IsBetterThan Q Acc B}
          if {Dist Acc.2} > {Dist B} then Q#B else Acc end
        end
      in
        {Record.foldLInd Scores IsBetterThan nil#~1}.1 % Acc = Question#Score
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
                false:{TreeBuilder {Map F RemoveQ}})
      end
    in
      if Data == nil then nil
      else
        NextQ = {NextQuestion Data}
      in
        if NextQ == nil then
          {Map Data fun {$ E} E.1 end}
        else
          {Split Data NextQ}
        end
      end
    end

    fun {GameDriver Tree}
      fun {Next Tree Last}
        case Tree
          of nil then {ProjectLib.surrender}
          [] question(Q true:T false:F) then
            case {ProjectLib.askQuestion Q}
              of oops then {Next Last Last}
              [] true then {Next T Tree}
              [] false then {Next F Tree}
            end
          [] List then {ProjectLib.found List}
        end
      end
      Result = {Next Tree Tree}
    in
      % {Browse Tree}

      if Result == false then
        {Print 'Mistakes were made...\n'}
        {Print {ProjectLib.surrender}}
      elseif {IsList Result} then
        {FPrint {List.foldL Result.2 fun {$ A B} A#","#B end Result.1}}
      else
        {FPrint Result}
      end
      
      if NoGUI == false then {FPrint '\n'} end

      unit % always return unit
    end
  in
    {ProjectLib.play opts(characters:ListOfCharacters driver:GameDriver 
                          noGUI:NoGUI builder:TreeBuilder 
                          autoPlay:ListOfAnswers oopsButton:true)}
    {File close}
    {Application.exit 0}
  end
end
