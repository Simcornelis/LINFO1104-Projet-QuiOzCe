functor
import
  ProjectLib
  Browser
  OS
  System
  Application
define
  CWD = {Atom.toString {OS.getCWD}}#"/"
  Browse = proc {$ Buf} {Browser.browse Buf} end
  Print = proc{$ S} {System.print S} end
  Args = {Application.getArgs record('nogui'(single type:bool default:false optional:true)
          'db'(single type:string default:CWD#"database.txt"))} 
in 
  local
    NoGUI = Args.'nogui'
    DB = Args.'db'
    ListOfCharacters = {ProjectLib.loadDatabase file Args.'db'}
    NewCharacter = {ProjectLib.loadCharacter file CWD#"new_character.txt"}
    % Vous devez modifier le code pour que cette variable soit
    % assigné un argument 	
    ListOfAnswersFile = CWD#"test_answers.txt"
    ListOfAnswers = {ProjectLib.loadCharacter file CWD#"test_answers.txt"}

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
    in
      if {Length Data} =< 1 orelse {Width Data.1} =< 1 then nil
      else {GetBestScoredQ {FoldL Data ScoreQuestions Start} {Length Data}}
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
      Result
      fun {Next Tree}
        case Tree
          of nil then {ProjectLib.surrender}
          [] question(Q true:T false:F) then
            if {ProjectLib.askQuestion Q} then {Next T}
            else {Next F} end
          [] List then {ProjectLib.found List}
        end
      end
    in
      % {Browse Tree}
      Result = {Next Tree}

      if Result == false then
        % Arf ! L'algorithme s'est trompé !
        {Print 'Je me suis trompé\n'}
        {Print {ProjectLib.surrender}}

        % warning, Browse does not work in noGUI mode
        {Browse {ProjectLib.askQuestion 'A-t-il des cheveux roux ?'}}
      else
        {Print Result}
      end
      
      unit % always return unit
    end
  in
    {ProjectLib.play opts(characters:ListOfCharacters driver:GameDriver 
                          noGUI:NoGUI builder:TreeBuilder 
                          autoPlay:ListOfAnswers newCharacter:NewCharacter)}
    {Application.exit 0}
  end
end
