unit msu2FenceUnit;

interface
uses
 System.Types;

procedure fDo;

implementation
uses
 msu5MPR;

procedure fF3;
(*Функция fF3 третья формула ограждения.*)
var
I : Integer;
J  : Integer;
K  : Integer;
L  : Boolean;
L1  : Boolean;
L2  : Boolean;
BEGIN
I := gv.fF3_I;
if (MPR_RWFences.List[I]._DA = 4) OR (MPR_RWFences.List[I]._DA = 1) then Exit;

CASE MPR_RWFences.List[I]._Step OF
0: (*Выбираем, какую из нечетных стрелок будем переводить*)
    begin
        IF MPR_RWFences.List[I].HighEvenFenceSolutions > 0 THEN
        begin
            FOR J := 0 TO MPR_RWFences.List[I].HighEvenFenceSolutions - 1 DO
            begin
                L := TRUE;
                IF MPR_RWFences.List[I].EvenFenceSolutions[J].HighPoints > 0 THEN
                begin
                    FOR K := 0 TO MPR_RWFences.List[I].EvenFenceSolutions[J].HighPoints - 1 DO
                    begin
                        IF (MPR_RWMainPoints.List[MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntIndex].MainTag = 0) AND
                        (NOT(MPR_RWMainPoints.List[MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntIndex]._OUT_K = MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntEnState + 3)) THEN
                        begin
                            L := FALSE;
                            MPR_RWMainPoints.List[MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntIndex].FBLK[I] := FALSE;
                        end;
                        IF (MPR_RWMainPoints.List[MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntIndex].MainTag = MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntDsState + 3) THEN
                        begin
                            L := FALSE;
                            MPR_RWMainPoints.List[MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntIndex].FBLK[I] := FALSE;
                        end;
                    end;
                end;
                IF L THEN
                begin
                    IF MPR_RWFences.List[I].EvenFenceSolutions[J].HighPoints > 0 THEN
                    begin
                        FOR K := 0 TO MPR_RWFences.List[I].EvenFenceSolutions[J].HighPoints - 1 DO
                        begin
                            IF ((MPR_RWMainPoints.List[MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntIndex].MainTag = 0) AND
                            (MPR_RWMainPoints.List[MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntIndex]._OUT_K = MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntEnState + 3))
                            OR (MPR_RWMainPoints.List[MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntIndex].MainTag = MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntEnState)
                            OR (MPR_RWMainPoints.List[MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntIndex].MainTag = MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntEnState + 3) THEN
                            begin
                                MPR_RWMainPoints.List[MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntIndex].FBLK[I] := TRUE;
                                MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].FenceStep := 2;
                            end
                            ELSE
                            begin
                                MPR_RWMainPoints.List[MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntIndex].FBLK[I] := FALSE;
                                MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].FenceStep := MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].FenceStep + 1;
                                MPR_RWMainPoints.List[MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntIndex]._Command_Fence := MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntEnState;
                            end;
                        end;
                    end;
                    MPR_RWFences.List[I]._Step := MPR_RWFences.List[I]._Step + 1;
                    break; (*выход из цикла, если решение возможно к исполнению*)
                end;
            end;
            IF NOT L THEN
            begin
                (*ни одно из решений не возможно*)
                MPR_RWFences.List[I]._Step := -1;
                MPR_RWFences.List[I]._DA := 1;
            end;
        end
        ELSE
        begin
            (*нечетных решений  нет, переходим к четным*)
            MPR_RWFences.List[I]._Step := MPR_RWFences.List[I]._Step + 2;
        end;
    end;
1: (*переводим выбранные стрелки*)
    begin
        IF MPR_RWFences.List[I].HighEvenFenceSolutions > 0 THEN
        begin
            L := TRUE;
            FOR J := 0 TO MPR_RWFences.List[I].HighEvenFenceSolutions - 1 DO
            begin
                IF MPR_RWFences.List[I].EvenFenceSolutions[J].HighPoints > 0 THEN
                begin
                    FOR K := 0 TO MPR_RWFences.List[I].EvenFenceSolutions[J].HighPoints - 1 DO
                    begin
                        IF MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].FenceStep = 1 THEN
                        begin
                            IF MPR_RWMainPoints.List[MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntIndex]._Result_Fence > 0 THEN
                            begin
                                MPR_RWMainPoints.List[MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntIndex]._Command_Fence := 0;
                                IF (MPR_RWMainPoints.List[MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntIndex]._Result_Fence = MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntEnState) OR
                                (MPR_RWMainPoints.List[MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntIndex]._Result_Fence = MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntEnState + 3) THEN
                                begin
                                    MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].FenceStep := 2;
                                    MPR_RWMainPoints.List[MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntIndex].FBLK[I] := TRUE;
                                end
                                ELSE
                                begin
                                    MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].FenceStep := 0;
                                    MPR_RWFences.List[I]._Step := -1;
                                    MPR_RWFences.List[I]._DA := 1;
                                    L := FALSE;
                                end;
                            end
                            ELSE
                            begin
                                L := FALSE;
                            end;
                        end;
                    end;
                end;
            end;
            IF L THEN
            begin
                FOR J := 0 TO MPR_RWFences.List[I].HighEvenFenceSolutions - 1 DO
                begin
                    IF MPR_RWFences.List[I].EvenFenceSolutions[J].HighPoints > 0 THEN
                    begin
                        FOR K := 0 TO MPR_RWFences.List[I].EvenFenceSolutions[J].HighPoints - 1 DO
                        begin
                            IF MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].FenceStep = 2 THEN
                            begin
                                IF (MPR_RWMainPoints.List[MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntIndex].MainTag = MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntEnState + 3) THEN
                                begin
                                    (*стрелка в нужном положении и заблокирована*)
                                    MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].FenceStep := 0;
                                end
                                ELSE
                                begin
                                    L := FALSE;
                                end;
                            end;
                        end;
                    end;
                end;
                IF L THEN
                begin
                    MPR_RWFences.List[I]._Step := MPR_RWFences.List[I]._Step + 1;
                end;
            end;
        end;

    end;
2:    (*Выбираем, какую из четных стрелок будем переводить*)
    begin
        IF MPR_RWFences.List[I].HighOddFenceSolutions > 0 THEN
        begin
            FOR J := 0 TO MPR_RWFences.List[I].HighOddFenceSolutions - 1 DO
            begin
                L := TRUE;
                IF MPR_RWFences.List[I].OddFenceSolutions[J].HighPoints > 0 THEN
                begin
                    FOR K := 0 TO MPR_RWFences.List[I].OddFenceSolutions[J].HighPoints - 1 DO
                    begin
                        IF (MPR_RWMainPoints.List[MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntIndex].MainTag = 0) AND
                        (NOT(MPR_RWMainPoints.List[MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntIndex]._OUT_K = MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntEnState + 3)) THEN
                        begin
                            L := FALSE;
                            MPR_RWMainPoints.List[MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntIndex].FBLK[I] := FALSE;
                        end;
                        IF (MPR_RWMainPoints.List[MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntIndex].MainTag = MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntDsState + 3) THEN
                        begin
                            L := FALSE;
                            MPR_RWMainPoints.List[MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntIndex].FBLK[I] := FALSE;
                        end;
                    end;
                end;
                IF L THEN
                begin
                    IF MPR_RWFences.List[I].OddFenceSolutions[J].HighPoints > 0 THEN
                    begin
                        FOR K := 0 TO MPR_RWFences.List[I].OddFenceSolutions[J].HighPoints - 1 DO
                        begin
                            IF ((MPR_RWMainPoints.List[MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntIndex].MainTag = 0) AND
                            (MPR_RWMainPoints.List[MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntIndex]._OUT_K = MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntEnState + 3))
                            OR (MPR_RWMainPoints.List[MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntIndex].MainTag = MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntEnState)
                            OR (MPR_RWMainPoints.List[MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntIndex].MainTag = MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntEnState + 3) THEN
                            begin
                                MPR_RWMainPoints.List[MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntIndex].FBLK[I] := TRUE;
                                MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].FenceStep := 2;
                            end
                            ELSE
                            begin
                                MPR_RWMainPoints.List[MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntIndex].FBLK[I] := FALSE;
                                MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].FenceStep := MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].FenceStep + 1;
                                MPR_RWMainPoints.List[MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntIndex]._Command_Fence := MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntEnState;
                            end;
                        end;
                    end;
                    MPR_RWFences.List[I]._Step := MPR_RWFences.List[I]._Step + 1;
                    break; (*выход из цикла, если решение возможно к исполнению*)
                end;
            end;
            IF NOT L THEN
            begin
                (*ни одно из решений не возможно*)
                MPR_RWFences.List[I]._Step := -1;
                MPR_RWFences.List[I]._DA := 1;
            end;
        end
        ELSE
        begin
            (*четных решений  нет, переходим к завершению*)
            MPR_RWFences.List[I]._Step := MPR_RWFences.List[I]._Step + 2;
        end;
    end;
3:    (*переводим выбранные стрелки*)
    begin
        IF MPR_RWFences.List[I].HighOddFenceSolutions > 0 THEN
        begin
            L := TRUE;
            FOR J := 0 TO MPR_RWFences.List[I].HighOddFenceSolutions - 1 DO
            begin
                IF MPR_RWFences.List[I].OddFenceSolutions[J].HighPoints > 0 THEN
                begin
                    FOR K := 0 TO MPR_RWFences.List[I].OddFenceSolutions[J].HighPoints - 1 DO
                    begin
                        IF MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].FenceStep = 1 THEN
                        begin
                            IF MPR_RWMainPoints.List[MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntIndex]._Result_Fence > 0 THEN
                            begin
                                MPR_RWMainPoints.List[MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntIndex]._Command_Fence := 0;
                                IF (MPR_RWMainPoints.List[MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntIndex]._Result_Fence = MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntEnState) OR
                                (MPR_RWMainPoints.List[MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntIndex]._Result_Fence = MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntEnState + 3) THEN
                                begin
                                    MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].FenceStep := 2;
                                    MPR_RWMainPoints.List[MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntIndex].FBLK[I] := TRUE;
                                end
                                ELSE
                                begin
                                    MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].FenceStep := 0;
                                    MPR_RWFences.List[I]._Step := -1;
                                    MPR_RWFences.List[I]._DA := 1;
                                    L := FALSE;
                                end;
                            end
                            ELSE
                            begin
                                L := FALSE;
                            end;
                        end;
                    end;
                end;
            end;
            IF L THEN
            begin
                FOR J := 0 TO MPR_RWFences.List[I].HighOddFenceSolutions - 1 DO
                begin
                    IF MPR_RWFences.List[I].OddFenceSolutions[J].HighPoints > 0 THEN
                    begin
                        FOR K := 0 TO MPR_RWFences.List[I].OddFenceSolutions[J].HighPoints - 1 DO
                        begin
                            IF MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].FenceStep = 2 THEN
                            begin
                                IF (MPR_RWMainPoints.List[MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntIndex].MainTag = MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntEnState + 3) THEN
                                begin
                                    (*стрелка в нужном положении и заблокирована*)
                                    MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].FenceStep := 0;
                                end
                                ELSE
                                begin
                                    L := FALSE;
                                end;
                            end;
                        end;
                    end;
                end;
                IF L THEN
                begin
                    MPR_RWFences.List[I]._Step := MPR_RWFences.List[I]._Step + 1;
                end;
            end;
        end;
    end;
4:    (*переход на следующую формулу*)
    begin
        MPR_RWFences.List[I]._OUT := TRUE;
        MPR_RWFences.List[I]._DA := 4;
        MPR_RWFences.List[I]._Step := -1;
        IF MPR_RWFenceGroups.List[MPR_RWFences.List[I].GroupIndex].FenceIndex = MPR_RWFences.List[I].IndexInGroup THEN
        begin
            MPR_RWFenceGroups.List[MPR_RWFences.List[I].GroupIndex].FenceIndex := -1;
        end;
    end;
end;

end;


procedure fDo;
(*Функция fDo управления ограждениями.*)
var
I : Integer;
J  : Integer;
K  : Integer;
L  : Boolean;
L1  : Boolean;
L2  : Boolean;
SctIdx  : Integer;
BEGIN
IF MPR_Params.HighRWFences < 0 THEN
begin
    Exit;
end;
(*обработка запросов к ограждениям МПР*)
(*запросы выполняются все,последовательно для каждого ограждения*)
FOR I:=0 TO MPR_Params.HighRWFences DO
begin
    IF NOT (MPR_RWFences.List[I]._IN = MPR_RWFences.List[I].Prev) THEN
    begin
        IF NOT MPR_RWFences.List[I]._IN THEN
        begin
            (*Запрос снят*)
            MPR_RWFences.List[I].DSCounter := 0;
            (*Пересборка других ограждений группы*)
            MPR_RWFences.List[I]._AE := FALSE;
            IF MPR_RWFenceGroups.List[MPR_RWFences.List[I].GroupIndex].FenceIndex = MPR_RWFences.List[I].IndexInGroup THEN
            begin
                MPR_RWFenceGroups.List[MPR_RWFences.List[I].GroupIndex].FenceIndex := -1;
                if MPR_RWFences.List[I].HighFencePoints > 0 then
                begin
                  for J := 0 to MPR_RWFences.List[I].HighFencePoints - 1 do
                  begin
                    MPR_RWMainPoints.List[MPR_RWFences.List[I].AllFencePoints[J]]._Command_Fence := 0;
                  end;//for j
                end;
            end;
            IF MPR_RWFences.List[I].MainTag > 1 THEN
            begin
                IF MPR_RWFenceGroups.List[MPR_RWFences.List[I].GroupIndex].HighFences > 0 THEN
                begin
                    FOR J:=0 TO MPR_RWFenceGroups.List[MPR_RWFences.List[I].GroupIndex].HighFences - 1 DO
                    begin
                        IF (MPR_RWFences.List[MPR_RWFenceGroups.List[MPR_RWFences.List[I].GroupIndex].Fences[J]].MainTag > 1) AND
                        NOT (MPR_RWFences.List[I].IndexInGroup = J) THEN
                        begin
                            MPR_RWFences.List[MPR_RWFenceGroups.List[MPR_RWFences.List[I].GroupIndex].Fences[J]]._DA := 6;
                            IF MPR_RWFenceGroups.List[MPR_RWFences.List[I].GroupIndex].FenceIndex = -1 THEN
                            begin
                                MPR_RWFenceGroups.List[MPR_RWFences.List[I].GroupIndex].FenceIndex := J;
                            end;
                        end;
                    end;
                end;
            end;
        end;
        MPR_RWFences.List[I].Prev := MPR_RWFences.List[I]._IN;
    end;
    (*формула сброса ограждения при разрыве связи с АРМ ДСП*)
    if MPR_Params.SafeMode then
    begin
      MPR_RWFences.List[I]._OUT := FALSE;
      MPR_RWFences.List[I]._DA := 0;
      IF MPR_RWFenceGroups.List[MPR_RWFences.List[I].GroupIndex].FenceIndex = MPR_RWFences.List[I].IndexInGroup THEN
      begin
          MPR_RWFenceGroups.List[MPR_RWFences.List[I].GroupIndex].FenceIndex := -1;
      end;
      Exit;
    end;
    CASE MPR_RWFences.List[I].MainTag OF
    0:
        begin
            IF MPR_RWFences.List[I].HighFencePoints > 0 THEN
            begin
                FOR J := 0 TO MPR_RWFences.List[I].HighFencePoints - 1 DO
                begin
                    MPR_RWMainPoints.List[MPR_RWFences.List[I].AllFencePoints[J]].FBLK[I] := FALSE;
                end;
            end;
            MPR_RWFences.List[I]._OUT := FALSE;
            MPR_RWFences.List[I]._DA := 0;
            MPR_RWFences.List[I].LPP := 0;
            MPR_RWFences.List[I].LPM := 0;
        end;
    1:
        begin
            IF MPR_RWFences.List[I].HighEvenFenceSolutions > 0 THEN
            begin
                FOR J := 0 TO MPR_RWFences.List[I].HighEvenFenceSolutions - 1 DO
                begin
                    L1 := TRUE;
                    IF MPR_RWFences.List[I].EvenFenceSolutions[J].HighPoints > 0 THEN
                    begin
                        FOR K := 0 TO MPR_RWFences.List[I].EvenFenceSolutions[J].HighPoints - 1 DO
                        begin
                            IF (MPR_RWMainPoints.List[MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntIndex].MainTag = 0) AND
                            (NOT(MPR_RWMainPoints.List[MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntIndex]._OUT_K = MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntEnState + 3)) THEN
                            begin
                                L1 := FALSE;
                            end;
                            IF (MPR_RWMainPoints.List[MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntIndex].MainTag = MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntDsState + 3) THEN
                            begin
                                L1 := FALSE;
                            end;
                            IF (MPR_RWMainPoints.List[MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntIndex].MainTag = 7) THEN
                            begin
                                L1 := FALSE;
                            end;
                        end;
                    end;
                    IF L1 THEN
                    begin
                        break;
                    end;
                end;
            end;
            IF MPR_RWFences.List[I].HighOddFenceSolutions > 0 THEN
            begin
                FOR J := 0 TO MPR_RWFences.List[I].HighOddFenceSolutions - 1 DO
                begin
                    L2 := TRUE;
                    IF MPR_RWFences.List[I].OddFenceSolutions[J].HighPoints > 0 THEN
                    begin
                        FOR K := 0 TO MPR_RWFences.List[I].OddFenceSolutions[J].HighPoints - 1 DO
                        begin
                            IF (MPR_RWMainPoints.List[MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntIndex].MainTag = 0) AND
                            (NOT(MPR_RWMainPoints.List[MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntIndex]._OUT_K = MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntEnState + 3)) THEN
                            begin
                                L2 := FALSE;
                            end;
                            IF (MPR_RWMainPoints.List[MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntIndex].MainTag = MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntDsState + 3) THEN
                            begin
                                L2 := FALSE;
                            end;
                            IF (MPR_RWMainPoints.List[MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntIndex].MainTag = 7) THEN
                            begin
                                L2 := FALSE;
                            end;
                        end;
                        IF L2 THEN
                        begin
                            break;
                        end;
                    end;
                end;
            end;
            IF L1 AND L2 THEN
            begin
                MPR_RWFences.List[I]._AE := FALSE;
            end;
            MPR_RWFences.List[I]._DA := 0;
        end;
    2:
        begin
            if (MPR_RWFences.List[I]._DA = 3) OR (MPR_RWFences.List[I]._DA = 1) then Exit;
            MPR_RWFences.List[I]._DeviceState := 0;
            MPR_RWFences.List[I].LPP := 0;
            MPR_RWFences.List[I].LPM := 0;
            MPR_RWFences.List[I]._DA := 0;
            IF MPR_RWFenceGroups.List[MPR_RWFences.List[I].GroupIndex].FenceIndex = MPR_RWFences.List[I].IndexInGroup THEN
            begin
                {IF MPR_RWFences.List[I].HighFencePoints > 0 THEN
                begin
                    FOR J := 0 TO MPR_RWFences.List[I].HighFencePoints - 1 DO
                    begin
                        MPR_RWMainPoints.List[MPR_RWFences.List[I].AllFencePoints[J]].FBLK[I] := FALSE;
                    end;
                end; }
                MPR_RWFences.List[I].Prior := 1;
                IF MPR_RWFences.List[I].HighEvenFenceSolutions > 0 THEN
                begin
                    FOR J := 0 TO MPR_RWFences.List[I].HighEvenFenceSolutions - 1 DO
                    begin
                        L := TRUE;
                        IF MPR_RWFences.List[I].EvenFenceSolutions[J].HighPoints > 0 THEN
                        begin
                            FOR K := 0 TO MPR_RWFences.List[I].EvenFenceSolutions[J].HighPoints - 1 DO
                            begin
                                MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].FenceStep := 0;
                                IF (MPR_RWMainPoints.List[MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntIndex].MainTag = 0) AND
                                (NOT(MPR_RWMainPoints.List[MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntIndex]._OUT_K = MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntEnState + 3)) THEN
                                begin
                                    L := FALSE;
                                    MPR_RWFences.List[I].LPP := MPR_RWFences.List[I].LPP OR MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PlusPos;
                                    MPR_RWFences.List[I].LPM := MPR_RWFences.List[I].LPM OR MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].MinusPos;
                                    MPR_RWMainPoints.List[MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntIndex].FBLK[I] := FALSE;
                                end;
                                IF (MPR_RWMainPoints.List[MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntIndex].MainTag = MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntDsState + 3) THEN
                                begin
                                    L := FALSE;
                                    MPR_RWFences.List[I].LPP := MPR_RWFences.List[I].LPP OR MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PlusPos;
                                    MPR_RWFences.List[I].LPM := MPR_RWFences.List[I].LPM OR MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].MinusPos;
                                    MPR_RWMainPoints.List[MPR_RWFences.List[I].EvenFenceSolutions[J].SolPoints[K].PntIndex].FBLK[I] := FALSE;
                                end;
                            end;
                        end;
                        IF L THEN
                        begin
                            break;
                        end;
                    end;
                    IF NOT L THEN
                    begin
                        MPR_RWFences.List[I].Prior := 0;
                    end;
                end;
                IF (MPR_RWFences.List[I].HighOddFenceSolutions > 0) AND (MPR_RWFences.List[I].Prior = 1) THEN
                begin
                    FOR J := 0 TO MPR_RWFences.List[I].HighOddFenceSolutions - 1 DO
                    begin
                        L := TRUE;
                        IF MPR_RWFences.List[I].OddFenceSolutions[J].HighPoints > 0 THEN
                        begin
                            FOR K := 0 TO MPR_RWFences.List[I].OddFenceSolutions[J].HighPoints - 1 DO
                            begin
                                MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].FenceStep := 0;
                                IF (MPR_RWMainPoints.List[MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntIndex].MainTag = 0) AND
                                (NOT(MPR_RWMainPoints.List[MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntIndex]._OUT_K = MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntEnState + 3)) THEN
                                begin
                                    L := FALSE;
                                    MPR_RWFences.List[I].LPP := MPR_RWFences.List[I].LPP OR MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PlusPos;
                                    MPR_RWFences.List[I].LPM := MPR_RWFences.List[I].LPM OR MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].MinusPos;
                                    MPR_RWMainPoints.List[MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntIndex].FBLK[I] := FALSE;
                                end;
                                IF (MPR_RWMainPoints.List[MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntIndex].MainTag = MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntDsState + 3) THEN
                                begin
                                    L := FALSE;
                                    MPR_RWFences.List[I].LPP := MPR_RWFences.List[I].LPP OR MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PlusPos;
                                    MPR_RWFences.List[I].LPM := MPR_RWFences.List[I].LPM OR MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].MinusPos;
                                    MPR_RWMainPoints.List[MPR_RWFences.List[I].OddFenceSolutions[J].SolPoints[K].PntIndex].FBLK[I] := FALSE;
                                end;
                            end;
                        end;
                        IF L THEN
                        begin
                            break;
                        end;
                    end;
                    IF NOT L THEN
                    begin
                        MPR_RWFences.List[I].Prior := 0;
                    end;
                end;
                IF MPR_RWFences.List[I].Prior = 1 THEN
                begin
                    MPR_RWFences.List[I]._DA := 3;
                    MPR_RWFences.List[I].Prior := 0;
                    MPR_RWFences.List[I]._Step := 0;
                end
                ELSE
                begin
                    //MPR_RWFences.List[I].BrokenPoints := MPR_RWFences.List[I].LocBrokenPoints;
                    MPR_RWFences.List[I]._DeviceState := MPR_RWFences.List[I]._DeviceState OR 4;
                    MPR_RWFences.List[I]._DA := 1;
                    MPR_RWFences.List[I]._AE := TRUE;
                    MPR_RWFenceGroups.List[MPR_RWFences.List[I].GroupIndex].FenceIndex := -1;
                end;
            end
            ELSE
            begin
                MPR_RWFences.List[I].Prior := 0;
                IF MPR_RWFenceGroups.List[MPR_RWFences.List[I].GroupIndex].FenceIndex = -1 THEN
                begin
                    MPR_RWFenceGroups.List[MPR_RWFences.List[I].GroupIndex].FenceIndex := MPR_RWFences.List[I].IndexInGroup;
                end;
            end;
        end;
    3:
        begin
            gv.fF3_I := I;
            fF3();
        end;
    6:
      begin
        if MPR_RWFences.List[I]._DA = 2 then Exit;
        MPR_RWFences.List[I]._OUT := FALSE;
        IF MPR_RWFences.List[I].HighFencePoints > 0 THEN
        begin
            FOR J := 0 TO MPR_RWFences.List[I].HighFencePoints - 1 DO
            begin
                MPR_RWMainPoints.List[MPR_RWFences.List[I].AllFencePoints[J]].FBLK[I] := FALSE;
            end;
        end;
        MPR_RWFences.List[I]._DA := 2;
      end
    ELSE
        begin
            if MPR_RWFences.List[I].MainTag <= 0 then
            begin
              (* MPR_RWFences.List[I]._DeviceState := 0;*)
              MPR_RWFences.List[I]._OUT := FALSE;
              MPR_RWFences.List[I]._DA := 0;
              IF MPR_RWFenceGroups.List[MPR_RWFences.List[I].GroupIndex].FenceIndex = MPR_RWFences.List[I].IndexInGroup THEN
              begin
                  MPR_RWFenceGroups.List[MPR_RWFences.List[I].GroupIndex].FenceIndex := -1;
              end;
            end;
        end;
    end;
end;
end;

end.
