1. Crie um script que traga o telefone mais recente de cada pessoa que aprove o uso dos seus dados
segundo a LGPD. Caso a pessoa não tenha telefone registrado na base, preencha o resultado com
“Sem telefone registrado”.

select pessoa.pessoa_id, pessoa.nome, pessoa.lgpd , Coalesce(telefone.ddd, 'Sem telefone registrado') as ddd, Coalesce(telefone.numero, 'Sem telefone registrado') as telefone 
from pessoa LEFT join telefone 
			on pessoa.pessoa_id = telefone.pessoa_id
where lgpd = true
order by pessoa_id asc, telefone.numero desc





------------------------------------------------------------------------------------//---------------------------------------------------------------------------







2. Crie um script que verifica se há um mesmo número de telefone (o telefone mais recente)
registrado para mais de uma pessoa ao mesmo tempo.



select pessoa.pessoa_id, pessoa.nome, pessoa.lgpd , Coalesce(telefone.ddd, 'Sem telefone registrado') as ddd, Coalesce(telefone.numero, 'Sem telefone registrado') as telefone 
from pessoa LEFT join telefone 
			on pessoa.pessoa_id = telefone.pessoa_id
where numero in (select numero
		from telefone
		group by numero
		having count(*) > 1
		order by numero desc)







----------------------------------------------------------------------------------------------//----------------------------------------------------------------







3. Crie um script que traga a primeira e última compra efetuada por uma pessoa. Compra efetuada é
aquela que não foi estornada. Caso não haja compras, preencha o resultado com “Sem compras
registradas”.

Create view antiga_compra
			AS SELECT pessoa_id, min (createdat)
	FROM compra c_min
	where not exists (select * 
						from compra_estornada
					 	where c_min.compra_id = compra_estornada.compra_id)
	group by c_min.pessoa_id

Create view ultime_compra
			AS SELECT pessoa_id, max (createdat)
	FROM compra c_max
	where not exists (select * 
						from compra_estornada
					 	where c_max.compra_id = compra_estornada.compra_id)
	group by c_max.pessoa_id




select pessoa.pessoa_id, pessoa.nome, antiga_compra.min, ultime_compra.max

from pessoa LEFT join antiga_compra 
			on pessoa.pessoa_id = antiga_compra.pessoa_id
			LEFT join ultime_compra 
			on pessoa.pessoa_id = ultime_compra.pessoa_id
			
order by pessoa_id asc










--------------------------------------------------------------------------------------------//------------------------------------------------------------------










4. Crie um script que traga quantas compras estornadas cada pessoa teve no último mês.

1° passo

create view estorno_mes_1 
			AS	select compra.pessoa_id ,pessoa.nome, count(compra_estornada.compra_id) as qtd_estorno
				from compra inner join compra_estornada
							on  compra.compra_id = compra_estornada.compra_id
				 	    inner join pessoa
				 			on pessoa.pessoa_id = compra.pessoa_id
				
				group by compra.pessoa_id, compra_estornada.createdat, pessoa.nome
				having compra_estornada.createdat > current_date - interval '1 month'
		
2° passo

select pessoa.pessoa_id, pessoa.nome,  Coalesce(estorno_mes_1.qtd_estorno, '0') as qtd_estorno
from pessoa LEFT join estorno_mes_1
			on pessoa.pessoa_id = estorno_mes_1.pessoa_id
			
order by qtd_estorno desc, pessoa.pessoa_id












------------------------------------------------------------------------------------//---------------------------------------------------------------------------
















5. Crie um script que gere um relatório com as seguintes informações:
- Nome da Pessoa

- ID da Pessoa

- Cliente desde

- Teve alguma compra efetuada no último mês?
view qtdvendas_mes_1

create view qtdvendas_mes_1
			AS SELECT compra.pessoa_id, count (compra.compra_id)
	FROM compra 
	where not exists (select * 
						from compra_estornada
					 	where compra.compra_id = compra_estornada.compra_id)
						and compra.createdat > current_date - interval '1 month'
	group by compra.pessoa_id

- Teve alguma compra estornada no último mês?
view estorno_mes_1 (exposto na questão 4)

- Valor total em compras efetuadas no último ano.
view valortotal_ano_1

create view valortotal_ano_1
			AS SELECT compra.pessoa_id, sum (compra.valor)
	FROM compra 
	where not exists (select * 
						from compra_estornada
					 	where compra.compra_id = compra_estornada.compra_id)
						and compra.createdat > current_date - interval '1 year'
	group by compra.pessoa_id
	order by compra.pessoa_id


- Menor de idade?








select pessoa.nome, pessoa.pessoa_id, to_char(pessoa.createdat,'DD/MM/YYYY') as Cliente_desde, 
	   Coalesce(qtdvendas_mes_1.count, '0') as qtdvendas,
	   Coalesce(estorno_mes_1.qtd_estorno, '0') as qtdestorno,
	   Coalesce(valortotal_ano_1.sum, '0') as total_$,
	   to_char(pessoa.data_nasc, 'DD/MM/YYYY')as data_nasc,
	   case 
	   		when extract(year from age(pessoa.data_nasc)) < '18' THEN 'Menor de idade'
														         else 'Maior de idade'
	   end												  
	from pessoa LEFT join qtdvendas_mes_1
			on pessoa.pessoa_id = qtdvendas_mes_1.pessoa_id
				LEFT join estorno_mes_1
			on  pessoa.pessoa_id = estorno_mes_1.pessoa_id
				LEFT join valortotal_ano_1
			on  pessoa.pessoa_id = valortotal_ano_1.pessoa_id




















