Criticisms and concerns from MFC post draft counterexamples

1. Chat interfaces do have some support in HCI research  
2. Focusing on structured artifact analysis makes tools inaccessible  
3. Sycophancy is not bad for some affective use cases  
4. Some artifact structure is prone to misinterpretation (e.g. token weights vs. answer confidence)  
5. Verification may not be well defined in many open-ended domains  
6. Scaffolding creates overhead if model output is already good; scaffolding should fall back to low-compute verification  
7. Don’t need to spell everything out every time  
   1. Want transparent, flexible, domain-appropriate context. Needs to be *model input* not necessary *user input* and definitely not limited to *current session user text input*  
8. Divergent steps (vs. convergent) must be handled gracefully  
9. Decomposition may have local and global constraints  
10. Inspection may be hard for novice users  
11. How does the interface interact with non-language models? With non-supervised learning models?  
12. Verification *cannot* be grounded in AI output  
13. Formal vs. practical compute complexity straddles contexts with different evaluation criteria  
14. Citation via abstract has different confidence than via deep read of a paper  
15. Being transparent about the level of scrutiny a model can apply is difficult  
16. A series of small changes can obfuscate  
17. Need to clarify exact intentions to communicate to users, and verify those via UXR  
18. Interface complexity may lead to cognitive overhead for users  
19. Reliability of studies is complex (even though replication-crisis issues are detectable)  
20. Automatically generated outputs might feel patronizing or like strong anchors  
21. Tracing across sessions needs massive improvement, ability to recurse  
22. Export of individual artifacts must include all necessary parent context from session

