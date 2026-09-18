// Calculadora Simples com Porcentagem e Visor Inteligente
integer CANAL_MENU = -888877;
integer handle_listener;

string visor_atual = "";
float valor_acumulado = 0.0;
string operador_atual = "";

// Formata o número omitindo as casas decimais se for inteiro (ex: 5.0 vira 5)
string formatar_visor(float valor)
{
    if (valor == (integer)valor) {
        return (string)((integer)valor);
    }
    return (string)valor;
}

// Constrói o texto do visor de forma limpa
string obter_texto_visor()
{
    string texto = "0";
    if (visor_atual != "") {
        texto = visor_atual;
    }
    if (valor_acumulado != 0.0) {
        texto = texto + "  [ " + formatar_visor(valor_acumulado) + " " + operador_atual + " ]";
    }
    return "\n Visor: " + texto + "\n";
}

// Menu Inicial (0 a 6)
abrir_menu_principal(key usuario)
{
    llListenRemove(handle_listener);
    handle_listener = llListen(CANAL_MENU, "", usuario, "");
    
    llDialog(usuario, obter_texto_visor(), 
             ["1", "2", "3", "+", 
              "4", "5", "6", "-", 
              "0", ".", "Mais", "C"], CANAL_MENU);
}

// Menu Secundário (7 a 9, Operações Avançadas e % )
abrir_menu_secundario(key usuario)
{
    llListenRemove(handle_listener);
    handle_listener = llListen(CANAL_MENU, "", usuario, "");
    
    llDialog(usuario, obter_texto_visor(), 
             ["7", "8", "9", "*", 
              "%", "=", "Voltar", "/", 
              "C", "Sair"], CANAL_MENU);
}

default
{
    state_entry()
    {
        llOwnerSay("Calculadora elegante pronta para uso.");
    }

    touch_start(integer total)
    {
        key usuario = llDetectedKey(0);
        if (usuario == llGetOwner()) {
            abrir_menu_principal(usuario);
        } else {
            llInstantMessage(usuario, "Acesso restrito ao proprietário.");
        }
    }

    listen(integer canal, string nome, key id, string mensagem)
    {
        if (canal != CANAL_MENU) return;
        
        if (mensagem == "Sair") {
            llListenRemove(handle_listener);
            return;
        }
        
        if (mensagem == "Mais") {
            abrir_menu_secundario(id);
            return;
        }
        
        if (mensagem == "Voltar") {
            abrir_menu_principal(id);
            return;
        }
        
        // Limpar tela (C)
        if (mensagem == "C") {
            visor_atual = "";
            valor_acumulado = 0.0;
            operador_atual = "";
            abrir_menu_principal(id);
            return;
        }
        
        // Inserção de Dígitos e Ponto
        if (mensagem == "0" || mensagem == "1" || mensagem == "2" || mensagem == "3" || 
            mensagem == "4" || mensagem == "5" || mensagem == "6" || mensagem == "7" || 
            mensagem == "8" || mensagem == "9" || mensagem == ".") 
        {
            visor_atual = visor_atual + mensagem;
            
            // Retorna ao menu correspondente
            if (mensagem == "7" || mensagem == "8" || mensagem == "9") {
                abrir_menu_secundario(id);
            } else {
                abrir_menu_principal(id);
            }
            return;
        }
        
        // Operadores Básicos (+, -, *, /)
        if (mensagem == "+" || mensagem == "-" || mensagem == "*" || mensagem == "/") 
        {
            if (visor_atual != "") {
                valor_acumulado = (float)visor_atual;
                operador_atual = mensagem;
                visor_atual = "";
            }
            abrir_menu_secundario(id);
            return;
        }
        
        // Cálculo de Porcentagem (%)
        if (mensagem == "%")
        {
            if (visor_atual != "") {
                float atual = (float)visor_atual;
                
                if (operador_atual == "+" || operador_atual == "-") {
                    atual = valor_acumulado * (atual / 100.0);
                } else {
                    atual = atual / 100.0;
                }
                
                visor_atual = formatar_visor(atual);
            }
            abrir_menu_secundario(id);
            return;
        }
        
        // Botão de Igual (=)
        if (mensagem == "=") 
        {
            if (operador_atual != "" && visor_atual != "") {
                float segundo_valor = (float)visor_atual;
                
                if (operador_atual == "+") valor_acumulado += segundo_valor;
                else if (operador_atual == "-") valor_acumulado -= segundo_valor;
                else if (operador_atual == "*") valor_acumulado *= segundo_valor;
                else if (operador_atual == "/") {
                    if (segundo_valor != 0.0) {
                        valor_acumulado /= segundo_valor;
                    } else {
                        llOwnerSay("Erro: Divisão por zero.");
                    }
                }
                
                visor_atual = formatar_visor(valor_acumulado);
                operador_atual = "";
            }
            abrir_menu_secundario(id);
            return;
        }
    }
}