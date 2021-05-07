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
      % returns score(q1:0 q2:0 ... qn:0) (each question starts with a score of 0)
      Start = {List.toRecord score {Map {Arity Data.1}.2 fun {$ E} E#0 end}}

      % returns a record with the score set for each question like score(q1:~2 q2:5 q3:0)
      fun {ScoreQuestions Acc Per}
        {Record.mapInd Acc fun {$ Q S} if Per.Q then S+1 else S-1 end end}
      end

      % returns the question with the best score
      fun {Best Q Acc X}
        if Acc.2 > {Abs X} then Q#{Abs X} else Acc end
      end

      Scores = {FoldL Data ScoreQuestions Start}
    in
      {Record.foldLInd Scores Best nil#{Length Data}}.1 % Acc = Question#Score
    end

    fun {TreeBuilder Data}
      case {NextQuestion Data}
        of nil then {Map Data fun {$ E} E.1 end} % keep only names list or nil (if none)
        [] NextQ then T F ClearQ in
          fun {ClearQ P} {Record.subtract P NextQ} end % remove question from db records
          {List.partition Data fun {$ E} E.NextQ end T F} % split in T and F (answer to NextQ)
          question(NextQ
                   true:{TreeBuilder {Map T ClearQ}}
                   false:{TreeBuilder {Map F ClearQ}})
      end
    end

    fun {GameDriver Tree}
      fun {Ask Tree}
        case Tree
          of nil then {ProjectLib.surrender}
          [] P|Ps then {ProjectLib.found P|Ps} % list of answers
          [] question(Q true:T false:F) then
            if {ProjectLib.askQuestion Q} then {Ask T} else {Ask F} end
        end
      end
    in
      case {Ask Tree}
        of false then {FPrint {ProjectLib.surrender}}
        [] H|T then {FPrint {FoldL T fun {$ A B} A#','#B end H}}
        [] Result then {FPrint Result}
      end
      
      if NoGUI == false then {FPrint '\n'} end

      unit % always return unit
    end
  in
    {ProjectLib.play opts(characters:ListOfCharacters autoPlay:ListOfAnswers
                          noGUI:NoGUI builder:TreeBuilder driver:GameDriver)}
    {File close}
    {Application.exit 0}
  end
end
