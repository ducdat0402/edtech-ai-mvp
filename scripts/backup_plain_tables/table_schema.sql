-- Non-INSERT statements (CREATE, ALTER, etc.)
-- Generated from: backup_plain.sql
-- Generated at: 2026-01-29T11:18:12.786858

ALTER TABLE ONLY public.domains
    ADD CONSTRAINT "PK_05a6b087662191c2ea7f7ddfc4d" PRIMARY KEY (id);
ALTER TABLE ONLY public.questions
    ADD CONSTRAINT "PK_08a6d4b0f49ff300bf3a0ca60ac" PRIMARY KEY (id);
ALTER TABLE ONLY public.content_edits
    ADD CONSTRAINT "PK_0a807569bb1042c52d38d6fd6af" PRIMARY KEY (id);
ALTER TABLE ONLY public.learning_nodes
    ADD CONSTRAINT "PK_0af22b3300706a2411cd586944d" PRIMARY KEY (id);
ALTER TABLE ONLY public.payments
    ADD CONSTRAINT "PK_197ab7af18c93fbb0c9b28b4a59" PRIMARY KEY (id);
ALTER TABLE ONLY public.subjects
    ADD CONSTRAINT "PK_1a023685ac2b051b4e557b0b280" PRIMARY KEY (id);
ALTER TABLE ONLY public.achievements
    ADD CONSTRAINT "PK_1bc19c37c6249f70186f318d71d" PRIMARY KEY (id);
ALTER TABLE ONLY public.user_quests
    ADD CONSTRAINT "PK_26397091cd37dde7d59fde6084d" PRIMARY KEY (id);
ALTER TABLE ONLY public.knowledge_nodes
    ADD CONSTRAINT "PK_2b3cbd4e30fc8716197028daf27" PRIMARY KEY (id);
ALTER TABLE ONLY public.user_achievements
    ADD CONSTRAINT "PK_3d94aba7e9ed55365f68b5e77fa" PRIMARY KEY (id);
ALTER TABLE ONLY public.roadmap_days
    ADD CONSTRAINT "PK_4092753e51a9afc3f2c27432e63" PRIMARY KEY (id);
ALTER TABLE ONLY public.knowledge_edges
    ADD CONSTRAINT "PK_42b3df48c5d5a1756783d427f11" PRIMARY KEY (id);
ALTER TABLE ONLY public.unlock_transactions
    ADD CONSTRAINT "PK_435e509ef2272f65e2122e54035" PRIMARY KEY (id);
ALTER TABLE ONLY public.user_currencies
    ADD CONSTRAINT "PK_4faf3eb8fdba98e879197fe0816" PRIMARY KEY (id);
ALTER TABLE ONLY public.skill_nodes
    ADD CONSTRAINT "PK_64e55eebf64198d616e8bc8ab73" PRIMARY KEY (id);
ALTER TABLE ONLY public.content_versions
    ADD CONSTRAINT "PK_77046b137eb8001947fc332e594" PRIMARY KEY (id);
ALTER TABLE ONLY public.user_progress
    ADD CONSTRAINT "PK_7b5eb2436efb0051fdf05cbe839" PRIMARY KEY (id);
ALTER TABLE ONLY public.adaptive_tests
    ADD CONSTRAINT "PK_9851067edab02ca53279e20e6e2" PRIMARY KEY (id);
ALTER TABLE ONLY public.skill_trees
    ADD CONSTRAINT "PK_9a17c0e811d4daa36aa69b71560" PRIMARY KEY (id);
ALTER TABLE ONLY public.roadmaps
    ADD CONSTRAINT "PK_9b0d527f9c64d15405c21e7ca54" PRIMARY KEY (id);
ALTER TABLE ONLY public.content_items
    ADD CONSTRAINT "PK_9c6bf4f28851752cee186915e39" PRIMARY KEY (id);
ALTER TABLE ONLY public.user_premium
    ADD CONSTRAINT "PK_9d18ae162ccccd64719207ecf5b" PRIMARY KEY (id);
ALTER TABLE ONLY public.quests
    ADD CONSTRAINT "PK_a037497017b64f530fe09c75364" PRIMARY KEY (id);
ALTER TABLE ONLY public.users
    ADD CONSTRAINT "PK_a3ffb1c0c8416b9fc6f907b7433" PRIMARY KEY (id);
ALTER TABLE ONLY public.quizzes
    ADD CONSTRAINT "PK_b24f0f7662cf6b3a0e7dba0a1b4" PRIMARY KEY (id);
ALTER TABLE ONLY public.reward_transactions
    ADD CONSTRAINT "PK_bbb060cbbc0bf4342665c360b5d" PRIMARY KEY (id);
ALTER TABLE ONLY public.user_behaviors
    ADD CONSTRAINT "PK_c345f97744cae055a1777e02c4c" PRIMARY KEY (id);
ALTER TABLE ONLY public.placement_tests
    ADD CONSTRAINT "PK_d024b5ad98461ffe65066501325" PRIMARY KEY (id);
ALTER TABLE ONLY public.edit_history
    ADD CONSTRAINT "PK_d5205110c72f360c7d10bd5ff03" PRIMARY KEY (id);
ALTER TABLE ONLY public.personal_mind_maps
    ADD CONSTRAINT "PK_e514921853e373c8b649e182f6b" PRIMARY KEY (id);
ALTER TABLE ONLY public.user_skill_progress
    ADD CONSTRAINT "PK_ebfb975f1a7d59b04b8315aa494" PRIMARY KEY (id);
ALTER TABLE ONLY public.personal_mind_maps
    ADD CONSTRAINT "UQ_54278701a08afc9db9584142e9f" UNIQUE ("userId", "subjectId");
ALTER TABLE ONLY public.user_currencies
    ADD CONSTRAINT "UQ_81c8c1a7711d9651c6d3158465c" UNIQUE ("userId");
ALTER TABLE ONLY public.users
    ADD CONSTRAINT "UQ_97672ac88f789774dd47f7c8be3" UNIQUE (email);
ALTER TABLE ONLY public.user_premium
    ADD CONSTRAINT "UQ_a6d374df28ba8ef7def1ee541f8" UNIQUE ("userId");
ALTER TABLE ONLY public.achievements
    ADD CONSTRAINT "UQ_cd74882f69ff37d7330e89c63d5" UNIQUE (code);
ALTER TABLE ONLY public.payments
    ADD CONSTRAINT "UQ_f413d3e1824c684723da101cad6" UNIQUE ("paymentCode");
CREATE UNIQUE INDEX "IDX_13925495f53978a4ce7b2143ca" ON public.skill_nodes USING btree ("skillTreeId", "order");
CREATE UNIQUE INDEX "IDX_3899b7199ecc017491a058ed70" ON public.user_quests USING btree ("userId", "questId", date);
CREATE UNIQUE INDEX "IDX_5a244161bb40f0d211a867736e" ON public.knowledge_edges USING btree ("fromNodeId", "toNodeId", type);
CREATE UNIQUE INDEX "IDX_8db0f19cd0a68e20a3393270be" ON public.user_skill_progress USING btree ("userId", "skillNodeId");
CREATE INDEX "IDX_9821d34ef16e19ab7510ba85ff" ON public.reward_transactions USING btree ("userId", "createdAt");
CREATE INDEX "IDX_be8bf1bb5b55915dfb35cca477" ON public.user_behaviors USING btree ("userId", "nodeId", "createdAt");
CREATE UNIQUE INDEX "IDX_c1acd69cf91b1e353634c152dd" ON public.user_achievements USING btree ("userId", "achievementId");
CREATE UNIQUE INDEX "IDX_db9e96bbed60e162aac221d403" ON public.user_progress USING btree ("userId", "nodeId");
CREATE UNIQUE INDEX "IDX_e3807f05ac57e287d13cd4fbd5" ON public.roadmap_days USING btree ("roadmapId", "dayNumber");
ALTER TABLE ONLY public.unlock_transactions
    ADD CONSTRAINT "FK_02d2ae8d3385514a0cd2cc53a49" FOREIGN KEY ("userId") REFERENCES public.users(id);
ALTER TABLE ONLY public.unlock_transactions
    ADD CONSTRAINT "FK_04737d53d7964e4f53795c29475" FOREIGN KEY ("subjectId") REFERENCES public.subjects(id);
ALTER TABLE ONLY public.roadmaps
    ADD CONSTRAINT "FK_07bcaf715c0cad376aca1e96555" FOREIGN KEY ("subjectId") REFERENCES public.subjects(id);
ALTER TABLE ONLY public.placement_tests
    ADD CONSTRAINT "FK_0f8780d89101ef496ab4dae3fe9" FOREIGN KEY ("userId") REFERENCES public.users(id);
ALTER TABLE ONLY public.user_behaviors
    ADD CONSTRAINT "FK_23a1a30653a907b0873927fc2d3" FOREIGN KEY ("nodeId") REFERENCES public.learning_nodes(id);
ALTER TABLE ONLY public.placement_tests
    ADD CONSTRAINT "FK_25a32f8e4e96b14eb99245499b9" FOREIGN KEY ("subjectId") REFERENCES public.subjects(id);
ALTER TABLE ONLY public.user_quests
    ADD CONSTRAINT "FK_262f95135c66a0fcf56a1c7f118" FOREIGN KEY ("questId") REFERENCES public.quests(id);
ALTER TABLE ONLY public.reward_transactions
    ADD CONSTRAINT "FK_2715dd04b02293a5eb765509218" FOREIGN KEY ("userId") REFERENCES public.users(id);
ALTER TABLE ONLY public.roadmaps
    ADD CONSTRAINT "FK_29f718c5a5cb41f2266d21ba207" FOREIGN KEY ("userId") REFERENCES public.users(id);
ALTER TABLE ONLY public.user_behaviors
    ADD CONSTRAINT "FK_2faa3a577b9bed8e5d849a47f00" FOREIGN KEY ("userId") REFERENCES public.users(id);
ALTER TABLE ONLY public.content_items
    ADD CONSTRAINT "FK_385abffedc921608730cbcf3516" FOREIGN KEY ("nodeId") REFERENCES public.learning_nodes(id);
ALTER TABLE ONLY public.content_edits
    ADD CONSTRAINT "FK_39f9a917943dcb1b09807fc5d12" FOREIGN KEY ("userId") REFERENCES public.users(id);
ALTER TABLE ONLY public.user_achievements
    ADD CONSTRAINT "FK_3ac6bc9da3e8a56f3f7082012dd" FOREIGN KEY ("userId") REFERENCES public.users(id);
ALTER TABLE ONLY public.quizzes
    ADD CONSTRAINT "FK_3bbaf48d81cd5d62908883cb416" FOREIGN KEY ("contentItemId") REFERENCES public.content_items(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.roadmap_days
    ADD CONSTRAINT "FK_43da70c0b7ceb981fdce5c7eedf" FOREIGN KEY ("nodeId") REFERENCES public.learning_nodes(id);
ALTER TABLE ONLY public.content_versions
    ADD CONSTRAINT "FK_44ae932f8cec3b113585326fbba" FOREIGN KEY ("contentItemId") REFERENCES public.content_items(id);
ALTER TABLE ONLY public.roadmap_days
    ADD CONSTRAINT "FK_457ecdaa29491dd8306877789a6" FOREIGN KEY ("roadmapId") REFERENCES public.roadmaps(id);
ALTER TABLE ONLY public.skill_trees
    ADD CONSTRAINT "FK_5633a5e121d33ca5e5ab980adae" FOREIGN KEY ("userId") REFERENCES public.users(id);
ALTER TABLE ONLY public.learning_nodes
    ADD CONSTRAINT "FK_574ad1e8f402b2913f8e652c93e" FOREIGN KEY ("domainId") REFERENCES public.domains(id);
ALTER TABLE ONLY public.content_versions
    ADD CONSTRAINT "FK_6021309003fb9e0c3e3e2936992" FOREIGN KEY ("relatedEditId") REFERENCES public.content_edits(id);
ALTER TABLE ONLY public.personal_mind_maps
    ADD CONSTRAINT "FK_6769c65f9373018aa67e7ef5de1" FOREIGN KEY ("subjectId") REFERENCES public.subjects(id);
ALTER TABLE ONLY public.user_achievements
    ADD CONSTRAINT "FK_6a5a5816f54d0044ba5f3dc2b74" FOREIGN KEY ("achievementId") REFERENCES public.achievements(id);
ALTER TABLE ONLY public.learning_nodes
    ADD CONSTRAINT "FK_75ace3cab6c56196e1f282f9ae6" FOREIGN KEY ("subjectId") REFERENCES public.subjects(id);
ALTER TABLE ONLY public.content_versions
    ADD CONSTRAINT "FK_784371accd22585fdfcd1fabe11" FOREIGN KEY ("createdByUserId") REFERENCES public.users(id);
ALTER TABLE ONLY public.user_currencies
    ADD CONSTRAINT "FK_81c8c1a7711d9651c6d3158465c" FOREIGN KEY ("userId") REFERENCES public.users(id);
ALTER TABLE ONLY public.user_progress
    ADD CONSTRAINT "FK_825aa4836c9f22e10f99956de22" FOREIGN KEY ("nodeId") REFERENCES public.learning_nodes(id);
ALTER TABLE ONLY public.personal_mind_maps
    ADD CONSTRAINT "FK_891aacc6f7701f17f75faff2fbc" FOREIGN KEY ("userId") REFERENCES public.users(id);
ALTER TABLE ONLY public.adaptive_tests
    ADD CONSTRAINT "FK_8c3807e3a37322914d467914e82" FOREIGN KEY ("userId") REFERENCES public.users(id);
ALTER TABLE ONLY public.user_skill_progress
    ADD CONSTRAINT "FK_95e06c20e51fe8b2c16eb7abafa" FOREIGN KEY ("userId") REFERENCES public.users(id);
ALTER TABLE ONLY public.quizzes
    ADD CONSTRAINT "FK_9984bbad8b51a91553298e8dd1e" FOREIGN KEY ("learningNodeId") REFERENCES public.learning_nodes(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.domains
    ADD CONSTRAINT "FK_a4916b7bce3f00ede64b2984888" FOREIGN KEY ("subjectId") REFERENCES public.subjects(id);
ALTER TABLE ONLY public.user_premium
    ADD CONSTRAINT "FK_a6d374df28ba8ef7def1ee541f8" FOREIGN KEY ("userId") REFERENCES public.users(id);
ALTER TABLE ONLY public.user_progress
    ADD CONSTRAINT "FK_b5d0e1b57bc6c761fb49e79bf89" FOREIGN KEY ("userId") REFERENCES public.users(id);
ALTER TABLE ONLY public.knowledge_edges
    ADD CONSTRAINT "FK_c0638604791c9ce9091c8d643cf" FOREIGN KEY ("toNodeId") REFERENCES public.knowledge_nodes(id);
ALTER TABLE ONLY public.content_edits
    ADD CONSTRAINT "FK_c1f531ecd5ccaf9bbc46cb65663" FOREIGN KEY ("contentItemId") REFERENCES public.content_items(id);
ALTER TABLE ONLY public.payments
    ADD CONSTRAINT "FK_d35cb3c13a18e1ea1705b2817b1" FOREIGN KEY ("userId") REFERENCES public.users(id);
ALTER TABLE ONLY public.knowledge_edges
    ADD CONSTRAINT "FK_d80623d315b4ae5cc4033224db3" FOREIGN KEY ("fromNodeId") REFERENCES public.knowledge_nodes(id);
ALTER TABLE ONLY public.edit_history
    ADD CONSTRAINT "FK_dd21225d361d2f8bb61902ee41f" FOREIGN KEY ("userId") REFERENCES public.users(id);
ALTER TABLE ONLY public.user_skill_progress
    ADD CONSTRAINT "FK_dda3a0f3c8b8b05052f743e26e4" FOREIGN KEY ("skillNodeId") REFERENCES public.skill_nodes(id);
ALTER TABLE ONLY public.content_versions
    ADD CONSTRAINT "FK_defacda35a1c7ba8a1a5f76563f" FOREIGN KEY ("approvedByUserId") REFERENCES public.users(id);
ALTER TABLE ONLY public.questions
    ADD CONSTRAINT "FK_e01d35c31e3ade999d9e569b79f" FOREIGN KEY ("subjectId") REFERENCES public.subjects(id);
ALTER TABLE ONLY public.edit_history
    ADD CONSTRAINT "FK_e0754f6c3c70c0e87e8f8f9c523" FOREIGN KEY ("contentItemId") REFERENCES public.content_items(id);
ALTER TABLE ONLY public.skill_nodes
    ADD CONSTRAINT "FK_e25e1e4e25e13a24d08dd9a33be" FOREIGN KEY ("learningNodeId") REFERENCES public.learning_nodes(id);
ALTER TABLE ONLY public.skill_nodes
    ADD CONSTRAINT "FK_e41cec650d81d37cceeaaa5ab43" FOREIGN KEY ("skillTreeId") REFERENCES public.skill_trees(id);
ALTER TABLE ONLY public.skill_trees
    ADD CONSTRAINT "FK_e892f70e9db48e8aaf80817a522" FOREIGN KEY ("subjectId") REFERENCES public.subjects(id);
ALTER TABLE ONLY public.user_quests
    ADD CONSTRAINT "FK_f489a5a5d968cfb35e44815fbd9" FOREIGN KEY ("userId") REFERENCES public.users(id);
ALTER TABLE ONLY public.adaptive_tests
    ADD CONSTRAINT "FK_f56f26f2c85a8b29983959444b7" FOREIGN KEY ("subjectId") REFERENCES public.subjects(id);
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO ledat0402;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO ledat0402;
