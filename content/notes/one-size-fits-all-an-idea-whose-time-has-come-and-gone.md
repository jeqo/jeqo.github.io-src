
[1] ‘One Size Fits All’: An Idea Whose Time Has Come and Gone - April 2005

http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.68.9136&rep=rep1&type=pdf

Initial Database players: DB2 and INGRESS (around 1980's), following vendors: Sybase, Oracle and Informix. 

The initial DBMS model: store relational tables row-by-row, uses B-trees for indexing, uses a cost-based optimized, 
and provides ACID transaction properties.

> It is a well known homily that warehouse applications run much better using bit-map indexes while OLTP users
prefer B-tree indexes. The reasons are straightforward: bit-map indexes are faster and more compact on
warehouse workloads, while failing to work well in OLTP environments. As a result, many vendors support
both B-tree indexes and bit-map indexes in their DBMS products.

> In addition, materialized views are a useful optimization tactic in warehouse worlds, but never in
OLTP worlds. In contrast, normal (“virtual”) views find acceptance in OLTP environments. 

"Inbound" versus "outbound" processing: 

> DBMS model of the world is what we term “outbound” processing 
