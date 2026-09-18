// PERSONAL PLANNER & EVENTS - DEMO VERSION (LSL) v4.07-DEMO
// Limited to a maximum of 2 active appointments for evaluation purposes.

string versao = "Personal Planner Demo v4.07";

integer canalMenu = -8811;
integer canalFluxo = -8822;

integer etapa = 0; 
string tempTitulo = "";
string tempTipo = "Event";
string tempDia = "";
string tempHora = "";
integer tempAntecedencia = 15;
integer idAlvoEdicao = 0;

string historicoCompromissos = "No history recorded.";
integer LIMITE_DEMO = 2; // Restringe a versão de testes a no máximo 2 eventos ativos

string formatarDataHora(integer timestamp)
{
    integer tempoLocal = timestamp - 10800; 
    if (tempoLocal < 0) tempoLocal = 0;

    integer ano = 1970;
    integer segundosPorDia = 86400;
    integer diasTotais = tempoLocal / segundosPorDia;
    integer segundosRestantes = tempoLocal % segundosPorDia;

    integer hora = segundosRestantes / 3600;
    integer minuto = (segundosRestantes % 3600) / 60;

    integer d = diasTotais;
    while(TRUE)
    {
        integer diasNoAno = 365;
        if ((ano % 4 == 0 && ano % 100 != 0) || (ano % 400 == 0)) diasNoAno = 366;
        if (d >= diasNoAno) { d -= diasNoAno; ano++; }
        else jump saiAnos;
    }
    @saiAnos;

    list mesesDias = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if ((ano % 4 == 0 && ano % 100 != 0) || (ano % 400 == 0)) mesesDias = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

    integer mes = 1;
    integer m = 0;
    while(m < 12)
    {
        integer diasMes = llList2Integer(mesesDias, m);
        if (d >= diasMes) { d -= diasMes; mes++; }
        else jump saiMeses;
        m++;
    }
    @saiMeses;

    integer dia = d + 1;

    string sDia = (string)dia; if (dia < 10) sDia = "0" + sDia;
    string sMes = (string)mes; if (mes < 10) sMes = "0" + sMes;
    string sHora = (string)hora; if (hora < 10) sHora = "0" + sHora;
    string sMinuto = (string)minuto; if (minuto < 10) sMinuto = "0" + sMinuto;

    return sDia + "/" + sMes + "/" + (string)ano + " " + sHora + ":" + sMinuto;
}

integer checarValidadeTimestamp(string dataStr, string horaStr)
{
    list partesData = llParseString2List(dataStr, ["/"], []);
    list partesHora = llParseString2List(horaStr, [":"], []);
    
    if (llGetListLength(partesData) != 3 || llGetListLength(partesHora) != 2) return 0;
    
    integer dia = (integer)llList2String(partesData, 0);
    integer mes = (integer)llList2String(partesData, 1);
    integer ano = (integer)llList2String(partesData, 2);
    integer hora = (integer)llList2String(partesHora, 0);
    integer min = (integer)llList2String(partesHora, 1);

    if (ano < 2024 || mes < 1 || mes > 12 || dia < 1 || dia > 31) return 0;
    if (hora < 0 || hora > 23 || min < 0 || min > 59) return 0;

    integer d = 0;
    integer y = 1970;
    while (y < ano)
    {
        integer bissexto = 0;
        if ((y % 4 == 0 && y % 100 != 0) || (y % 400 == 0)) bissexto = 1;
        d += 365 + bissexto;
        y++;
    }

    list mesesDias = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if ((ano % 4 == 0 && ano % 100 != 0) || (ano % 400 == 0)) mesesDias = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

    if (dia > llList2Integer(mesesDias, mes - 1)) return 0;

    integer i = 0;
    while (i < mes - 1)
    {
        d += llList2Integer(mesesDias, i);
        i++;
    }

    d += (dia - 1);
    integer timestamp = (d * 86400) + (hora * 3600) + (min * 60) + 10800; 

    if (timestamp <= llGetUnixTime()) return -1;

    return timestamp;
}

adicionarAoHistorico(string titulo, string tipo, string acao, integer timestamp)
{
    string registro = acao + ": " + titulo + " (" + tipo + ") - Ref: " + formatarDataHora(timestamp);
    
    if (historicoCompromissos == "No history recorded.")
    {
        historicoCompromissos = registro;
    }
    else
    {
        historicoCompromissos = historicoCompromissos + "\n" + registro;
    }
    llLinksetDataWrite("historico", historicoCompromissos);
}

carregarEstado()
{
    string h = llLinksetDataRead("historico");
    if (h != "") historicoCompromissos = h;
}

atualizarTextoFlutuante()
{
    integer total = (integer)llLinksetDataRead("total_eventos");
    if (total <= 0)
    {
        llSetText("📅 PERSONAL PLANNER [DEMO]\nNo appointments registered.\n(Max limit: 2 events)", <1.0, 0.6, 0.0>, 1.0);
        return;
    }

    integer agora = llGetUnixTime();
    integer menorTempo = 2147483647;
    string proximoNome = "None";

    integer i = 1;
    while (i <= total)
    {
        string dados = llLinksetDataRead("evento_" + (string)i);
        if (dados != "")
        {
            list partes = llParseString2List(dados, ["|"], []);
            string titulo = llList2String(partes, 0);
            string tipo = llList2String(partes, 1);
            integer timestamp = (integer)llList2String(partes, 2);

            if (tipo == "Birthday" && timestamp < agora)
            {
                timestamp += 31536000; 
            }

            if (timestamp > agora && timestamp < menorTempo)
            {
                menorTempo = timestamp;
                proximoNome = titulo;
            }
        }
        i++;
    }

    if (menorTempo == 2147483647)
    {
        llSetText("📅 PERSONAL PLANNER [DEMO]\nNo upcoming future events.\nSlots used: " + (string)total + "/" + (string)LIMITE_DEMO, <1.0, 0.6, 0.0>, 1.0);
    }
    else
    {
        string dataFmt = formatarDataHora(menorTempo);
        llSetText("📅 NEXT APPOINTMENT [DEMO]:\n" + proximoNome + "\n🕒 " + dataFmt + "\nSlots used: " + (string)total + "/" + (string)LIMITE_DEMO, <1.0, 0.6, 0.0>, 1.0);
    }
}

default
{
    state_entry()
    {
        llSetObjectName("Personal Planner Demo v4.07");
        carregarEstado();
        llSetTimerEvent(60.0);
        
        llListen(canalMenu, "", llGetOwner(), "");
        llListen(canalFluxo, "", llGetOwner(), "");
        
        atualizarTextoFlutuante();
    }

    touch_start(integer total_number)
    {
        if (llDetectedKey(0) == llGetOwner())
        {
            list botoes = ["Delete", "History", "Reset All", "View List", "Add", "Edit"];
            llDialog(llGetOwner(), "Personal Planner [DEMO PANEL]\nEvaluation Version (Max 2 events)\nChoose an option:", botoes, canalMenu);
        }
        else
        {
            llRegionSayTo(llDetectedKey(0), 0, "This personal planner demo is restricted to the owner.");
        }
    }

    listen(integer channel, string name, key id, string message)
    {
        if (channel == canalMenu)
        {
            if (message == "Add")
            {
                integer totalAtual = (integer)llLinksetDataRead("total_eventos");
                if (totalAtual >= LIMITE_DEMO)
                {
                    llOwnerSay("⚠️ DEMO LIMIT REACHED: You can only create up to " + (string)LIMITE_DEMO + " appointments in this trial version. Delete an existing event or get the full version!");
                    return;
                }

                etapa = 1;
                tempTitulo = "";
                llTextBox(id, "Step 1/5 [DEMO]: Enter the appointment TITLE:", canalFluxo);
            }
            else if (message == "View List")
            {
                integer total = (integer)llLinksetDataRead("total_eventos");
                if (total <= 0)
                {
                    llOwnerSay("📂 Your demo planner is empty.");
                    return;
                }

                string listaCompleta = "📂 YOUR REGISTERED APPOINTMENTS [DEMO (" + (string)total + "/" + (string)LIMITE_DEMO + ")]:\n\n";
                integer i = 1;
                while (i <= total)
                {
                    string dados = llLinksetDataRead("evento_" + (string)i);
                    if (dados != "")
                    {
                        list partes = llParseString2List(dados, ["|"], []);
                        string titulo = llList2String(partes, 0);
                        string tipo = llList2String(partes, 1);
                        integer timestamp = (integer)llList2String(partes, 2);
                        integer antecedencia = (integer)llList2String(partes, 3);
                        
                        listaCompleta += "[" + (string)i + "] " + titulo + " (" + tipo + ") - " + formatarDataHora(timestamp) + " [Alert: " + (string)antecedencia + "m]\n";
                    }
                    i++;
                }
                llOwnerSay(listaCompleta);
            }
            else if (message == "Edit")
            {
                integer total = (integer)llLinksetDataRead("total_eventos");
                if (total <= 0)
                {
                    llOwnerSay("⚠️ There are no events to edit.");
                    return;
                }
                etapa = 7;
                llTextBox(id, "Enter the NUMBER of the event you want to EDIT:", canalFluxo);
            }
            else if (message == "Delete")
            {
                integer total = (integer)llLinksetDataRead("total_eventos");
                if (total <= 0)
                {
                    llOwnerSay("⚠️ There are no events to delete.");
                    return;
                }
                etapa = 6;
                llTextBox(id, "Enter the NUMBER of the appointment you want to cancel/remove:", canalFluxo);
            }
            else if (message == "History")
            {
                llOwnerSay("📜 APPOINTMENT HISTORY [DEMO]:\n\n" + historicoCompromissos);
            }
            else if (message == "Reset All")
            {
                etapa = 12;
                llTextBox(id, "⚠️ WARNING: You requested to erase EVERYTHING!\n\nThis will permanently remove all registered appointments and event history.\n\nTo confirm, type exactly: YES", canalFluxo);
            }
        }
        else if (channel == canalFluxo)
        {
            // ADD - 1: Title
            if (etapa == 1)
            {
                tempTitulo = llStringTrim(message, STRING_TRIM);
                if (tempTitulo == "")
                {
                    llTextBox(id, "⚠️ Invalid title. Please enter again:", canalFluxo);
                    return;
                }
                etapa = 2;
                llDialog(id, "Step 2/5: Choose the appointment type:", ["Event", "Birthday"], canalFluxo);
            }
            // ADD - 2: Type
            else if (etapa == 2)
            {
                tempTipo = message;
                etapa = 3;
                llTextBox(id, "Step 3/5: Enter the DATE in DD/MM/YYYY format\n(Ex: 25/12/2026):", canalFluxo);
            }
            // ADD - 3: Date
            else if (etapa == 3)
            {
                tempDia = llStringTrim(message, STRING_TRIM);
                list pData = llParseString2List(tempDia, ["/"], []);
                if (llGetListLength(pData) != 3)
                {
                    llOwnerSay("❌ ERROR: Incorrect date format! Use DD/MM/YYYY.");
                    llTextBox(id, "Step 3/5: Enter the DATE again in DD/MM/YYYY format:", canalFluxo);
                    return;
                }

                integer diaVal = (integer)llList2String(pData, 0);
                integer mesVal = (integer)llList2String(pData, 1);
                integer anoVal = (integer)llList2String(pData, 2);

                if (anoVal < 2024 || mesVal < 1 || mesVal > 12 || diaVal < 1 || diaVal > 31)
                {
                    llOwnerSay("❌ ERROR: Invalid date (day, month, or year out of bounds).");
                    llTextBox(id, "Step 3/5: Enter a valid DATE (DD/MM/YYYY):", canalFluxo);
                    return;
                }

                etapa = 4;
                llTextBox(id, "Step 4/5: Enter the TIME in HH:MM format\n(Ex: 14:30):", canalFluxo);
            }
            // ADD - 4: Time
            else if (etapa == 4)
            {
                tempHora = llStringTrim(message, STRING_TRIM);
                list pHora = llParseString2List(tempHora, [":"], []);
                if (llGetListLength(pHora) != 2)
                {
                    llOwnerSay("❌ ERROR: Incorrect time format! Use HH:MM.");
                    llTextBox(id, "Step 4/5: Enter the TIME again in HH:MM format:", canalFluxo);
                    return;
                }

                integer horaVal = (integer)llList2String(pHora, 0);
                integer minVal = (integer)llList2String(pHora, 1);
                if (horaVal < 0 || horaVal > 23 || minVal < 0 || minVal > 59)
                {
                    llOwnerSay("❌ ERROR: Invalid time (hours 00-23 and minutes 00-59).");
                    llTextBox(id, "Step 4/5: Enter a valid TIME (HH:MM):", canalFluxo);
                    return;
                }

                integer testeTemp = checarValidadeTimestamp(tempDia, tempHora);
                if (testeTemp == -1)
                {
                    llOwnerSay("❌ SUBMISSION ERROR: The date/time (" + tempDia + " at " + tempHora + ") has already passed!");
                    llTextBox(id, "Step 4/5: Enter a valid future TIME (HH:MM):", canalFluxo);
                    return;
                }
                else if (testeTemp == 0)
                {
                    llOwnerSay("❌ SUBMISSION ERROR: Invalid date or time.");
                    llTextBox(id, "Step 4/5: Enter a valid TIME (HH:MM):", canalFluxo);
                    return;
                }

                etapa = 5;
                llDialog(id, "Step 5/5: Minutes of advance notice for the alert:", ["0", "15", "30", "60"], canalFluxo);
            }
            // ADD - 5: Notice & Final Save
            else if (etapa == 5)
            {
                tempAntecedencia = (integer)message;
                integer timestampFinal = checarValidadeTimestamp(tempDia, tempHora);

                if (timestampFinal <= 0)
                {
                    llOwnerSay("❌ Temporal error during registration. Restart the process.");
                    etapa = 0;
                    return;
                }

                integer total = (integer)llLinksetDataRead("total_eventos");
                if (total >= LIMITE_DEMO)
                {
                    llOwnerSay("⚠️ Demo limit reached during finalization.");
                    etapa = 0;
                    return;
                }

                total++;
                string registro = tempTitulo + "|" + tempTipo + "|" + (string)timestampFinal + "|" + (string)tempAntecedencia;
                llLinksetDataWrite("evento_" + (string)total, registro);
                llLinksetDataWrite("total_eventos", (string)total);

                etapa = 0;
                atualizarTextoFlutuante();
                llOwnerSay("✅ Appointment successfully registered in DEMO mode!");
            }
            
            // MANUAL DELETION
            else if (etapa == 6)
            {
                integer idExcluir = (integer)message;
                integer total = (integer)llLinksetDataRead("total_eventos");

                if (idExcluir > 0 && idExcluir <= total)
                {
                    string dadosExcluidos = llLinksetDataRead("evento_" + (string)idExcluir);
                    list partes = llParseString2List(dadosExcluidos, ["|"], []);
                    string titulo = llList2String(partes, 0);
                    string tipo = llList2String(partes, 1);
                    integer timestamp = (integer)llList2String(partes, 2);

                    adicionarAoHistorico(titulo, tipo, "❌ Cancelled/Removed", timestamp);

                    llLinksetDataDelete("evento_" + (string)idExcluir);
                    llOwnerSay("🗑️ Event #" + (string)idExcluir + " (" + titulo + ") cancelled and sent to history.");
                    atualizarTextoFlutuante();
                }
                else
                {
                    llOwnerSay("⚠️ Invalid number.");
                }
                etapa = 0;
            }

            // EDIT - 1: Select ID
            else if (etapa == 7)
            {
                idAlvoEdicao = (integer)message;
                integer total = (integer)llLinksetDataRead("total_eventos");

                if (idAlvoEdicao > 0 && idAlvoEdicao <= total)
                {
                    string dadosAtuais = llLinksetDataRead("evento_" + (string)idAlvoEdicao);
                    list partes = llParseString2List(dadosAtuais, ["|"], []);
                    tempTitulo = llList2String(partes, 0);
                    tempTipo = llList2String(partes, 1);

                    etapa = 8;
                    llTextBox(id, "Editing Event #" + (string)idAlvoEdicao + "\nEnter the NEW TITLE (Current: " + tempTitulo + "):", canalFluxo);
                }
                else
                {
                    llOwnerSay("⚠️ Invalid number for editing.");
                    etapa = 0;
                }
            }
            // EDIT - 2: New Title
            else if (etapa == 8)
            {
                string novoTitulo = llStringTrim(message, STRING_TRIM);
                if (novoTitulo != "") tempTitulo = novoTitulo;

                etapa = 9;
                llTextBox(id, "Enter the NEW DATE in DD/MM/YYYY format:", canalFluxo);
            }
            // EDIT - 3: New Date
            else if (etapa == 9)
            {
                tempDia = llStringTrim(message, STRING_TRIM);
                list pData = llParseString2List(tempDia, ["/"], []);
                if (llGetListLength(pData) != 3)
                {
                    llOwnerSay("❌ ERROR: Incorrect date format! Use DD/MM/YYYY.");
                    llTextBox(id, "Enter the NEW DATE again (DD/MM/YYYY):", canalFluxo);
                    return;
                }

                integer diaVal = (integer)llList2String(pData, 0);
                integer mesVal = (integer)llList2String(pData, 1);
                integer anoVal = (integer)llList2String(pData, 2);

                if (anoVal < 2024 || mesVal < 1 || mesVal > 12 || diaVal < 1 || diaVal > 31)
                {
                    llOwnerSay("❌ ERROR: Invalid date.");
                    llTextBox(id, "Enter a valid NEW DATE (DD/MM/YYYY):", canalFluxo);
                    return;
                }

                etapa = 10;
                llTextBox(id, "Enter the NEW TIME in HH:MM format:", canalFluxo);
            }
            // EDIT - 4: New Time
            else if (etapa == 10)
            {
                tempHora = llStringTrim(message, STRING_TRIM);
                list pHora = llParseString2List(tempHora, [":"], []);
                if (llGetListLength(pHora) != 2)
                {
                    llOwnerSay("❌ ERROR: Incorrect time format! Use HH:MM.");
                    llTextBox(id, "Enter the NEW TIME again (HH:MM):", canalFluxo);
                    return;
                }

                integer horaVal = (integer)llList2String(pHora, 0);
                integer minVal = (integer)llList2String(pHora, 1);
                if (horaVal < 0 || horaVal > 23 || minVal < 0 || minVal > 59)
                {
                    llOwnerSay("❌ ERROR: Invalid time.");
                    llTextBox(id, "Enter a valid NEW TIME (HH:MM):", canalFluxo);
                    return;
                }

                integer testeTemp = checarValidadeTimestamp(tempDia, tempHora);
                if (testeTemp == -1)
                {
                    llOwnerSay("❌ EDIT ERROR: The new date/time (" + tempDia + " at " + tempHora + ") has already passed!");
                    llTextBox(id, "Enter a valid future NEW TIME (HH:MM):", canalFluxo);
                    return;
                }
                else if (testeTemp == 0)
                {
                    llOwnerSay("❌ EDIT ERROR: Invalid date or time.");
                    llTextBox(id, "Enter a valid NEW TIME (HH:MM):", canalFluxo);
                    return;
                }

                etapa = 11;
                llDialog(id, "New notice lead time:", ["0", "15", "30", "60"], canalFluxo);
            }
            // EDIT - 5: Confirmation & Final Save
            else if (etapa == 11)
            {
                tempAntecedencia = (integer)message;
                integer timestampFinal = checarValidadeTimestamp(tempDia, tempHora);

                if (timestampFinal <= 0)
                {
                    llOwnerSay("❌ Temporal error during editing.");
                    etapa = 0;
                    return;
                }

                string novoRegistro = tempTitulo + "|" + tempTipo + "|" + (string)timestampFinal + "|" + (string)tempAntecedencia;
                llLinksetDataWrite("evento_" + (string)idAlvoEdicao, novoRegistro);

                adicionarAoHistorico(tempTitulo, tempTipo, "✏️ Edited/Rescheduled", timestampFinal);

                etapa = 0;
                atualizarTextoFlutuante();
                llOwnerSay("✅ Event #" + (string)idAlvoEdicao + " successfully updated!");
            }
            
            // RESET ALL - Confirmation Validation
            else if (etapa == 12)
            {
                string resposta = llToUpper(llStringTrim(message, STRING_TRIM));
                if (resposta == "YES")
                {
                    llLinksetDataReset();
                    llLinksetDataWrite("total_eventos", "0");
                    historicoCompromissos = "No history recorded.";
                    atualizarTextoFlutuante();
                    llOwnerSay("🗑️ Operation complete: Demo planner and history completely wiped.");
                }
                else
                {
                    llOwnerSay("🛡️ Operation cancelled for safety. Your data was preserved.");
                }
                etapa = 0;
            }
        }
    }

    timer()
    {
        integer agora = llGetUnixTime();
        integer total = (integer)llLinksetDataRead("total_eventos");
        if (total <= 0) return;

        integer i = 1;
        while (i <= total)
        {
            string dados = llLinksetDataRead("evento_" + (string)i);
            if (dados != "")
            {
                list partes = llParseString2List(dados, ["|"], []);
                string titulo = llList2String(partes, 0);
                string tipo = llList2String(partes, 1);
                integer timestamp = (integer)llList2String(partes, 2);
                integer antecedenciaMin = (integer)llList2String(partes, 3);

                integer momentoAlarme = timestamp - (antecedenciaMin * 60);

                if (agora >= momentoAlarme && agora < (momentoAlarme + 60))
                {
                    if (antecedenciaMin > 0)
                    {
                        llOwnerSay("🔔 EARLY REMINDER [DEMO]!\nThe appointment \"" + titulo + "\" (" + tipo + ") starts in " + (string)antecedenciaMin + " minutes!");
                    }
                    else
                    {
                        llOwnerSay("🔔 APPOINTMENT ALERT [DEMO]!\nThe appointment \"" + titulo + "\" (" + tipo + ") is happening now!");
                    }
                }

                if (agora >= timestamp && tipo != "Birthday")
                {
                    adicionarAoHistorico(titulo, tipo, "✔ Completed", timestamp);
                    llLinksetDataDelete("evento_" + (string)i);
                    atualizarTextoFlutuante();
                }
            }
            i++;
        }
    }
}