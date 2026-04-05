--
-- PostgreSQL database dump
--


-- Dumped from database version 17.6
-- Dumped by pg_dump version 18.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: achievements_rarity_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.achievements_rarity_enum AS ENUM (
    'common',
    'uncommon',
    'rare',
    'epic',
    'legendary'
);


--
-- Name: achievements_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.achievements_type_enum AS ENUM (
    'milestone',
    'streak',
    'completion',
    'perfect_score',
    'collection',
    'social',
    'quest_master'
);


--
-- Name: adaptive_tests_currentdifficulty_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.adaptive_tests_currentdifficulty_enum AS ENUM (
    'beginner',
    'intermediate',
    'advanced'
);


--
-- Name: adaptive_tests_overalllevel_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.adaptive_tests_overalllevel_enum AS ENUM (
    'beginner',
    'intermediate',
    'advanced'
);


--
-- Name: content_edits_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.content_edits_status_enum AS ENUM (
    'pending',
    'approved',
    'rejected'
);


--
-- Name: content_edits_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.content_edits_type_enum AS ENUM (
    'add_video',
    'add_image',
    'add_text',
    'update_content'
);


--
-- Name: knowledge_edges_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.knowledge_edges_type_enum AS ENUM (
    'prerequisite',
    'related',
    'part_of',
    'requires',
    'leads_to'
);


--
-- Name: knowledge_nodes_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.knowledge_nodes_type_enum AS ENUM (
    'subject',
    'domain',
    'learning_node',
    'concept',
    'lesson'
);


--
-- Name: reward_transactions_source_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.reward_transactions_source_enum AS ENUM (
    'content_item',
    'quest',
    'skill_node',
    'daily_streak',
    'bonus',
    'topic',
    'domain',
    'purchase'
);


--
-- Name: skill_nodes_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.skill_nodes_type_enum AS ENUM (
    'skill',
    'concept',
    'practice',
    'boss',
    'reward'
);


--
-- Name: user_skill_progress_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.user_skill_progress_status_enum AS ENUM (
    'locked',
    'unlocked',
    'in_progress',
    'completed'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: achievements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.achievements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying NOT NULL,
    name character varying NOT NULL,
    description text,
    type public.achievements_type_enum NOT NULL,
    rarity public.achievements_rarity_enum DEFAULT 'common'::public.achievements_rarity_enum NOT NULL,
    requirements jsonb NOT NULL,
    rewards jsonb,
    "iconUrl" character varying,
    "imageUrl" character varying,
    "order" integer DEFAULT 0 NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: adaptive_tests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.adaptive_tests (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "userId" uuid NOT NULL,
    "subjectId" uuid NOT NULL,
    status character varying DEFAULT 'in_progress'::character varying NOT NULL,
    "currentDomainId" character varying,
    "currentTopicId" character varying,
    "currentNodeId" character varying,
    "currentDifficulty" public.adaptive_tests_currentdifficulty_enum DEFAULT 'intermediate'::public.adaptive_tests_currentdifficulty_enum NOT NULL,
    "domainsToTest" jsonb DEFAULT '[]'::jsonb NOT NULL,
    "topicsToTest" jsonb DEFAULT '[]'::jsonb NOT NULL,
    "nodesToTest" jsonb DEFAULT '[]'::jsonb NOT NULL,
    "testedDomains" jsonb DEFAULT '[]'::jsonb NOT NULL,
    "testedTopics" jsonb DEFAULT '[]'::jsonb NOT NULL,
    "testedNodes" jsonb DEFAULT '[]'::jsonb NOT NULL,
    responses jsonb DEFAULT '[]'::jsonb NOT NULL,
    "topicAssessments" jsonb DEFAULT '[]'::jsonb NOT NULL,
    "adaptiveState" jsonb,
    score integer,
    "overallLevel" public.adaptive_tests_overalllevel_enum,
    "strongAreas" jsonb,
    "weakAreas" jsonb,
    "recommendedPath" jsonb,
    "startedAt" timestamp without time zone,
    "completedAt" timestamp without time zone,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "estimatedQuestions" integer DEFAULT 20 NOT NULL
);


--
-- Name: chat_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_messages (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    "userId" uuid NOT NULL,
    username character varying NOT NULL,
    message text NOT NULL,
    "userLevel" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "replyToId" uuid
);


--
-- Name: community_status_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.community_status_comments (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    "statusId" uuid NOT NULL,
    "userId" uuid NOT NULL,
    content text NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: community_status_reactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.community_status_reactions (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    "statusId" uuid NOT NULL,
    "userId" uuid NOT NULL,
    kind character varying(16) NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: community_statuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.community_statuses (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    "userId" uuid NOT NULL,
    content text NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: direct_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.direct_messages (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    "senderId" uuid NOT NULL,
    "receiverId" uuid NOT NULL,
    content text NOT NULL,
    "replyToId" uuid,
    "readAt" timestamp without time zone,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: domains; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.domains (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "subjectId" uuid NOT NULL,
    name character varying NOT NULL,
    description text,
    "order" integer DEFAULT 0 NOT NULL,
    metadata jsonb,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    difficulty character varying(20) DEFAULT 'medium'::character varying,
    "expReward" integer DEFAULT 0 NOT NULL,
    "coinReward" integer DEFAULT 0 NOT NULL
);


--
-- Name: friend_activities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.friend_activities (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    "userId" uuid NOT NULL,
    type character varying NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: friendships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.friendships (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    "requesterId" uuid NOT NULL,
    "addresseeId" uuid NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: knowledge_edges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.knowledge_edges (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "fromNodeId" uuid NOT NULL,
    "toNodeId" uuid NOT NULL,
    type public.knowledge_edges_type_enum NOT NULL,
    weight double precision DEFAULT '1'::double precision NOT NULL,
    description text,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: knowledge_nodes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.knowledge_nodes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    description text,
    type public.knowledge_nodes_type_enum NOT NULL,
    "entityId" character varying,
    metadata jsonb,
    embedding jsonb,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: learning_communication_attempts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.learning_communication_attempts (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    "userId" uuid NOT NULL,
    "nodeId" uuid NOT NULL,
    "lessonType" character varying,
    "responseText" text NOT NULL,
    "aiScores" jsonb DEFAULT '{}'::jsonb NOT NULL,
    "feedbackShort" text,
    "totalScore" integer NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: learning_nodes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.learning_nodes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "subjectId" uuid NOT NULL,
    title character varying NOT NULL,
    description text,
    "order" integer DEFAULT 0 NOT NULL,
    prerequisites jsonb DEFAULT '[]'::jsonb NOT NULL,
    "contentStructure" jsonb NOT NULL,
    metadata jsonb,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "domainId" uuid,
    type character varying(20) DEFAULT 'theory'::character varying,
    difficulty character varying(20) DEFAULT 'medium'::character varying,
    "lessonType" character varying(20),
    "lessonData" jsonb,
    "endQuiz" jsonb,
    "topicId" uuid,
    "expReward" integer DEFAULT 0 NOT NULL,
    "coinReward" integer DEFAULT 0 NOT NULL,
    "contributorId" uuid
);


--
-- Name: learning_quiz_attempts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.learning_quiz_attempts (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    "userId" character varying NOT NULL,
    "nodeId" character varying NOT NULL,
    "lessonType" character varying(32),
    score integer NOT NULL,
    passed boolean DEFAULT false NOT NULL,
    "totalQuestions" integer NOT NULL,
    "correctCount" integer NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "questionResults" jsonb DEFAULT '[]'::jsonb NOT NULL,
    "confidencePercent" integer
);


--
-- Name: lesson_type_content_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lesson_type_content_versions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "nodeId" uuid NOT NULL,
    "lessonType" character varying(20) NOT NULL,
    version integer NOT NULL,
    "lessonData" jsonb NOT NULL,
    "endQuiz" jsonb,
    "contributorId" character varying,
    title character varying,
    description text,
    note text,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: lesson_type_contents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lesson_type_contents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "nodeId" uuid NOT NULL,
    "lessonType" character varying(20) NOT NULL,
    "lessonData" jsonb NOT NULL,
    "endQuiz" jsonb NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "userId" uuid NOT NULL,
    "paymentCode" character varying NOT NULL,
    "packageName" character varying NOT NULL,
    amount numeric(12,0) NOT NULL,
    description character varying,
    "durationDays" integer DEFAULT 0 NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    "transactionId" character varying,
    "bankReference" character varying,
    "paidAt" timestamp without time zone,
    "expiresAt" timestamp without time zone NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "diamondAmount" integer DEFAULT 0 NOT NULL
);


--
-- Name: pending_contributions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pending_contributions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    type character varying NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    "contributorId" uuid NOT NULL,
    title character varying NOT NULL,
    description text,
    data jsonb NOT NULL,
    "parentSubjectId" uuid,
    "parentDomainId" uuid,
    "reviewedBy" uuid,
    "reviewNote" text,
    "reviewedAt" timestamp without time zone,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    action character varying DEFAULT 'create'::character varying NOT NULL,
    "contextDescription" text,
    "parentTopicId" uuid
);


--
-- Name: personal_mind_maps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.personal_mind_maps (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "userId" uuid NOT NULL,
    "subjectId" uuid NOT NULL,
    "learningGoal" text,
    nodes jsonb DEFAULT '[]'::jsonb NOT NULL,
    edges jsonb DEFAULT '[]'::jsonb NOT NULL,
    "aiConversationHistory" jsonb,
    "completedNodes" integer DEFAULT 0 NOT NULL,
    "totalNodes" integer DEFAULT 0 NOT NULL,
    "progressPercent" double precision DEFAULT '0'::double precision NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: placement_tests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.placement_tests (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "userId" uuid NOT NULL,
    "subjectId" uuid,
    status character varying DEFAULT 'not_started'::character varying NOT NULL,
    questions jsonb DEFAULT '[]'::jsonb NOT NULL,
    "currentQuestionIndex" integer DEFAULT 0 NOT NULL,
    score integer,
    level character varying,
    "adaptiveData" jsonb,
    "startedAt" timestamp without time zone,
    "completedAt" timestamp without time zone,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: query-result-cache; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."query-result-cache" (
    id integer NOT NULL,
    identifier character varying,
    "time" bigint NOT NULL,
    duration integer NOT NULL,
    query text NOT NULL,
    result text NOT NULL
);


--
-- Name: query-result-cache_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."query-result-cache_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: query-result-cache_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."query-result-cache_id_seq" OWNED BY public."query-result-cache".id;


--
-- Name: questions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.questions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "subjectId" uuid,
    question character varying NOT NULL,
    options jsonb NOT NULL,
    "correctAnswer" integer NOT NULL,
    difficulty character varying DEFAULT 'beginner'::character varying NOT NULL,
    explanation text,
    metadata jsonb,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: quests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quests (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title character varying NOT NULL,
    description text,
    type character varying NOT NULL,
    requirements jsonb NOT NULL,
    rewards jsonb NOT NULL,
    metadata jsonb,
    "isDaily" boolean DEFAULT true NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: reward_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reward_transactions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "userId" uuid NOT NULL,
    source public.reward_transactions_source_enum NOT NULL,
    "sourceId" character varying,
    "sourceName" character varying,
    xp integer DEFAULT 0 NOT NULL,
    coins integer DEFAULT 0 NOT NULL,
    shards jsonb,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: roadmap_days; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roadmap_days (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "roadmapId" uuid NOT NULL,
    "dayNumber" integer NOT NULL,
    "scheduledDate" date NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    "nodeId" uuid,
    content jsonb,
    "completedAt" timestamp without time zone,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: roadmaps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roadmaps (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "userId" uuid NOT NULL,
    "subjectId" uuid NOT NULL,
    status character varying DEFAULT 'active'::character varying NOT NULL,
    "totalDays" integer DEFAULT 30 NOT NULL,
    "currentDay" integer DEFAULT 0 NOT NULL,
    "startDate" date NOT NULL,
    "endDate" date,
    metadata jsonb,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: self_leadership_checkins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.self_leadership_checkins (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    "userId" uuid NOT NULL,
    "nodeId" uuid,
    "lessonType" character varying,
    "weekStart" date NOT NULL,
    "followedPlan" boolean NOT NULL,
    "deviationReason" character varying,
    "nextAction" character varying,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: subjects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subjects (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    description text,
    track character varying DEFAULT 'explorer'::character varying NOT NULL,
    price integer,
    metadata jsonb,
    "unlockConditions" jsonb,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "subjectType" character varying DEFAULT 'community'::character varying NOT NULL,
    "approvalStatus" character varying DEFAULT 'approved'::character varying NOT NULL,
    "ownerUserId" uuid
);


--
-- Name: test_embeddings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.test_embeddings (
    id integer NOT NULL,
    embedding public.vector(1536)
);


--
-- Name: test_embeddings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.test_embeddings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_embeddings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.test_embeddings_id_seq OWNED BY public.test_embeddings.id;


--
-- Name: topics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.topics (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "domainId" uuid NOT NULL,
    name character varying NOT NULL,
    description text,
    "order" integer DEFAULT 0 NOT NULL,
    metadata jsonb,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    difficulty character varying(20) DEFAULT 'medium'::character varying,
    "expReward" integer DEFAULT 0 NOT NULL,
    "coinReward" integer DEFAULT 0 NOT NULL
);


--
-- Name: unlock_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.unlock_transactions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "userId" uuid NOT NULL,
    "subjectId" uuid NOT NULL,
    "unlockType" character varying NOT NULL,
    "coinsUsed" integer NOT NULL,
    "paymentAmount" integer,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    "paymentReference" text,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: user_achievements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_achievements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "userId" uuid NOT NULL,
    "achievementId" uuid NOT NULL,
    "unlockedAt" timestamp without time zone NOT NULL,
    "rewardsClaimed" boolean DEFAULT false NOT NULL,
    "rewardsClaimedAt" timestamp without time zone,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: user_badges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_badges (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    "userId" uuid NOT NULL,
    code character varying NOT NULL,
    name character varying NOT NULL,
    "iconUrl" character varying,
    metadata jsonb,
    "awardedAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: user_behaviors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_behaviors (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "userId" uuid NOT NULL,
    "nodeId" uuid NOT NULL,
    "contentItemId" character varying,
    action character varying NOT NULL,
    metrics jsonb DEFAULT '{}'::jsonb NOT NULL,
    context jsonb,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: user_blocks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_blocks (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    "blockerId" uuid NOT NULL,
    "blockedId" uuid NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: user_currencies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_currencies (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "userId" uuid NOT NULL,
    coins integer DEFAULT 0 NOT NULL,
    xp integer DEFAULT 0 NOT NULL,
    "currentStreak" integer DEFAULT 0 NOT NULL,
    "lastActiveDate" date,
    shards jsonb DEFAULT '{}'::jsonb NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    level integer DEFAULT 1 NOT NULL,
    version integer NOT NULL,
    diamonds integer DEFAULT 0 NOT NULL,
    "maxStreak" integer DEFAULT 0 NOT NULL,
    "weeklyXp" integer DEFAULT 0 NOT NULL
);


--
-- Name: user_domain_progress; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_domain_progress (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "userId" uuid NOT NULL,
    "domainId" uuid NOT NULL,
    "isCompleted" boolean DEFAULT false NOT NULL,
    "completedAt" timestamp without time zone,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: user_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_items (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    "userId" uuid NOT NULL,
    "itemId" character varying NOT NULL,
    quantity integer DEFAULT 1 NOT NULL,
    "expiresAt" timestamp without time zone,
    "isActive" boolean DEFAULT false NOT NULL,
    "activatedAt" timestamp without time zone,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: user_opened_nodes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_opened_nodes (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    "userId" uuid NOT NULL,
    "nodeId" uuid NOT NULL,
    "diamondsPaid" integer DEFAULT 0 NOT NULL,
    "openedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "coinsPaid" integer DEFAULT 0 NOT NULL
);


--
-- Name: user_premium; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_premium (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "userId" uuid NOT NULL,
    "isPremium" boolean DEFAULT false NOT NULL,
    "premiumExpiresAt" timestamp without time zone,
    "totalDaysPurchased" integer DEFAULT 0 NOT NULL,
    "lastPaymentId" character varying,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: user_progress; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_progress (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "userId" uuid NOT NULL,
    "nodeId" uuid NOT NULL,
    "completedItems" jsonb DEFAULT '{}'::jsonb NOT NULL,
    "progressPercentage" double precision DEFAULT '0'::double precision NOT NULL,
    "isCompleted" boolean DEFAULT false NOT NULL,
    "completedAt" timestamp without time zone,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    "completedLessonTypes" jsonb DEFAULT '[]'::jsonb NOT NULL
);


--
-- Name: user_quests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_quests (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "userId" uuid NOT NULL,
    "questId" uuid NOT NULL,
    date date NOT NULL,
    status character varying DEFAULT 'active'::character varying NOT NULL,
    progress integer DEFAULT 0 NOT NULL,
    "completedAt" timestamp without time zone,
    "claimedAt" timestamp without time zone,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: user_topic_progress; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_topic_progress (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "userId" uuid NOT NULL,
    "topicId" uuid NOT NULL,
    "isCompleted" boolean DEFAULT false NOT NULL,
    "completedAt" timestamp without time zone,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: user_unlocks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_unlocks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    "userId" uuid NOT NULL,
    "unlockLevel" character varying(20) NOT NULL,
    "subjectId" uuid,
    "domainId" uuid,
    "topicId" uuid,
    "diamondsCost" integer NOT NULL,
    "lessonsCount" integer NOT NULL,
    "discountPercent" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: user_weekly_plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_weekly_plans (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    "userId" uuid NOT NULL,
    "weekStart" date NOT NULL,
    "targetSessions" integer DEFAULT 3 NOT NULL,
    "targetLessons" integer DEFAULT 3 NOT NULL,
    "plannedDays" integer[] DEFAULT '{1,3,5}'::integer[] NOT NULL,
    status character varying DEFAULT 'active'::character varying NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email character varying NOT NULL,
    password character varying NOT NULL,
    "fullName" character varying,
    phone character varying,
    "currentStreak" integer DEFAULT 0 NOT NULL,
    "totalXP" integer DEFAULT 0 NOT NULL,
    "onboardingData" jsonb,
    "placementTestScore" integer,
    "placementTestLevel" character varying,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL,
    "updatedAt" timestamp without time zone DEFAULT now() NOT NULL,
    role character varying DEFAULT 'user'::character varying NOT NULL,
    "authProvider" character varying DEFAULT 'local'::character varying NOT NULL,
    "resetPasswordToken" character varying,
    "resetPasswordExpires" timestamp with time zone,
    "avatarUrl" text
);


--
-- Name: weekly_reward_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.weekly_reward_history (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    "userId" uuid NOT NULL,
    "weekCode" character varying NOT NULL,
    rank integer NOT NULL,
    "weeklyXp" integer NOT NULL,
    "diamondsAwarded" integer DEFAULT 0 NOT NULL,
    "badgeCode" character varying,
    notified boolean DEFAULT false NOT NULL,
    "createdAt" timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: query-result-cache id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."query-result-cache" ALTER COLUMN id SET DEFAULT nextval('public."query-result-cache_id_seq"'::regclass);


--
-- Name: test_embeddings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_embeddings ALTER COLUMN id SET DEFAULT nextval('public.test_embeddings_id_seq'::regclass);


--
-- Name: domains PK_05a6b087662191c2ea7f7ddfc4d; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.domains
    ADD CONSTRAINT "PK_05a6b087662191c2ea7f7ddfc4d" PRIMARY KEY (id);


--
-- Name: questions PK_08a6d4b0f49ff300bf3a0ca60ac; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT "PK_08a6d4b0f49ff300bf3a0ca60ac" PRIMARY KEY (id);


--
-- Name: friendships PK_08af97d0be72942681757f07bc8; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.friendships
    ADD CONSTRAINT "PK_08af97d0be72942681757f07bc8" PRIMARY KEY (id);


--
-- Name: learning_nodes PK_0af22b3300706a2411cd586944d; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.learning_nodes
    ADD CONSTRAINT "PK_0af22b3300706a2411cd586944d" PRIMARY KEY (id);


--
-- Name: user_blocks PK_0bae5f5cab7574a84889462187c; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_blocks
    ADD CONSTRAINT "PK_0bae5f5cab7574a84889462187c" PRIMARY KEY (id);


--
-- Name: user_badges PK_0ca139216824d745a930065706a; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_badges
    ADD CONSTRAINT "PK_0ca139216824d745a930065706a" PRIMARY KEY (id);


--
-- Name: user_domain_progress PK_1197008b748675a3f9d3e9858bc; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_domain_progress
    ADD CONSTRAINT "PK_1197008b748675a3f9d3e9858bc" PRIMARY KEY (id);


--
-- Name: payments PK_197ab7af18c93fbb0c9b28b4a59; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT "PK_197ab7af18c93fbb0c9b28b4a59" PRIMARY KEY (id);


--
-- Name: subjects PK_1a023685ac2b051b4e557b0b280; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subjects
    ADD CONSTRAINT "PK_1a023685ac2b051b4e557b0b280" PRIMARY KEY (id);


--
-- Name: achievements PK_1bc19c37c6249f70186f318d71d; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.achievements
    ADD CONSTRAINT "PK_1bc19c37c6249f70186f318d71d" PRIMARY KEY (id);


--
-- Name: user_quests PK_26397091cd37dde7d59fde6084d; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_quests
    ADD CONSTRAINT "PK_26397091cd37dde7d59fde6084d" PRIMARY KEY (id);


--
-- Name: self_leadership_checkins PK_2b28660657de2173b4ff2e0ada9; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.self_leadership_checkins
    ADD CONSTRAINT "PK_2b28660657de2173b4ff2e0ada9" PRIMARY KEY (id);


--
-- Name: knowledge_nodes PK_2b3cbd4e30fc8716197028daf27; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_nodes
    ADD CONSTRAINT "PK_2b3cbd4e30fc8716197028daf27" PRIMARY KEY (id);


--
-- Name: user_achievements PK_3d94aba7e9ed55365f68b5e77fa; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_achievements
    ADD CONSTRAINT "PK_3d94aba7e9ed55365f68b5e77fa" PRIMARY KEY (id);


--
-- Name: roadmap_days PK_4092753e51a9afc3f2c27432e63; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roadmap_days
    ADD CONSTRAINT "PK_4092753e51a9afc3f2c27432e63" PRIMARY KEY (id);


--
-- Name: chat_messages PK_40c55ee0e571e268b0d3cd37d10; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT "PK_40c55ee0e571e268b0d3cd37d10" PRIMARY KEY (id);


--
-- Name: knowledge_edges PK_42b3df48c5d5a1756783d427f11; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_edges
    ADD CONSTRAINT "PK_42b3df48c5d5a1756783d427f11" PRIMARY KEY (id);


--
-- Name: unlock_transactions PK_435e509ef2272f65e2122e54035; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.unlock_transactions
    ADD CONSTRAINT "PK_435e509ef2272f65e2122e54035" PRIMARY KEY (id);


--
-- Name: user_currencies PK_4faf3eb8fdba98e879197fe0816; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_currencies
    ADD CONSTRAINT "PK_4faf3eb8fdba98e879197fe0816" PRIMARY KEY (id);


--
-- Name: pending_contributions PK_5ffc24c537bb35e754ead5b1495; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pending_contributions
    ADD CONSTRAINT "PK_5ffc24c537bb35e754ead5b1495" PRIMARY KEY (id);


--
-- Name: learning_communication_attempts PK_659e77aa46ae9239eef703cff92; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.learning_communication_attempts
    ADD CONSTRAINT "PK_659e77aa46ae9239eef703cff92" PRIMARY KEY (id);


--
-- Name: friend_activities PK_65d7b0b22aea4729570613263ac; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.friend_activities
    ADD CONSTRAINT "PK_65d7b0b22aea4729570613263ac" PRIMARY KEY (id);


--
-- Name: query-result-cache PK_6a98f758d8bfd010e7e10ffd3d3; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."query-result-cache"
    ADD CONSTRAINT "PK_6a98f758d8bfd010e7e10ffd3d3" PRIMARY KEY (id);


--
-- Name: user_unlocks PK_6d1549d755cab385952135b069f; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_unlocks
    ADD CONSTRAINT "PK_6d1549d755cab385952135b069f" PRIMARY KEY (id);


--
-- Name: user_items PK_73bc2ecd8f15ae345af4d8c3c09; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_items
    ADD CONSTRAINT "PK_73bc2ecd8f15ae345af4d8c3c09" PRIMARY KEY (id);


--
-- Name: user_progress PK_7b5eb2436efb0051fdf05cbe839; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_progress
    ADD CONSTRAINT "PK_7b5eb2436efb0051fdf05cbe839" PRIMARY KEY (id);


--
-- Name: lesson_type_content_versions PK_80a917daef055a0c7878047f00f; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lesson_type_content_versions
    ADD CONSTRAINT "PK_80a917daef055a0c7878047f00f" PRIMARY KEY (id);


--
-- Name: direct_messages PK_8373c1bb93939978ef05ae650d1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.direct_messages
    ADD CONSTRAINT "PK_8373c1bb93939978ef05ae650d1" PRIMARY KEY (id);


--
-- Name: adaptive_tests PK_9851067edab02ca53279e20e6e2; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adaptive_tests
    ADD CONSTRAINT "PK_9851067edab02ca53279e20e6e2" PRIMARY KEY (id);


--
-- Name: roadmaps PK_9b0d527f9c64d15405c21e7ca54; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roadmaps
    ADD CONSTRAINT "PK_9b0d527f9c64d15405c21e7ca54" PRIMARY KEY (id);


--
-- Name: user_premium PK_9d18ae162ccccd64719207ecf5b; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_premium
    ADD CONSTRAINT "PK_9d18ae162ccccd64719207ecf5b" PRIMARY KEY (id);


--
-- Name: quests PK_a037497017b64f530fe09c75364; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quests
    ADD CONSTRAINT "PK_a037497017b64f530fe09c75364" PRIMARY KEY (id);


--
-- Name: user_weekly_plans PK_a09831375a75bee03a0a6324343; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_weekly_plans
    ADD CONSTRAINT "PK_a09831375a75bee03a0a6324343" PRIMARY KEY (id);


--
-- Name: users PK_a3ffb1c0c8416b9fc6f907b7433; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT "PK_a3ffb1c0c8416b9fc6f907b7433" PRIMARY KEY (id);


--
-- Name: lesson_type_contents PK_ab8755390575859e61d3f29c5b6; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lesson_type_contents
    ADD CONSTRAINT "PK_ab8755390575859e61d3f29c5b6" PRIMARY KEY (id);


--
-- Name: community_status_reactions PK_b4608ced1aeef39d3f7a1f61cf2; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.community_status_reactions
    ADD CONSTRAINT "PK_b4608ced1aeef39d3f7a1f61cf2" PRIMARY KEY (id);


--
-- Name: community_status_comments PK_b7efc303941e6ffd09df658ac88; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.community_status_comments
    ADD CONSTRAINT "PK_b7efc303941e6ffd09df658ac88" PRIMARY KEY (id);


--
-- Name: reward_transactions PK_bbb060cbbc0bf4342665c360b5d; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reward_transactions
    ADD CONSTRAINT "PK_bbb060cbbc0bf4342665c360b5d" PRIMARY KEY (id);


--
-- Name: user_topic_progress PK_bd04b1cdf363a1ac5cead8de7ef; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_topic_progress
    ADD CONSTRAINT "PK_bd04b1cdf363a1ac5cead8de7ef" PRIMARY KEY (id);


--
-- Name: user_behaviors PK_c345f97744cae055a1777e02c4c; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_behaviors
    ADD CONSTRAINT "PK_c345f97744cae055a1777e02c4c" PRIMARY KEY (id);


--
-- Name: placement_tests PK_d024b5ad98461ffe65066501325; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.placement_tests
    ADD CONSTRAINT "PK_d024b5ad98461ffe65066501325" PRIMARY KEY (id);


--
-- Name: weekly_reward_history PK_dcef23eb1cae73f06f0bdeafc3a; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.weekly_reward_history
    ADD CONSTRAINT "PK_dcef23eb1cae73f06f0bdeafc3a" PRIMARY KEY (id);


--
-- Name: topics PK_e4aa99a3fa60ec3a37d1fc4e853; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.topics
    ADD CONSTRAINT "PK_e4aa99a3fa60ec3a37d1fc4e853" PRIMARY KEY (id);


--
-- Name: personal_mind_maps PK_e514921853e373c8b649e182f6b; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personal_mind_maps
    ADD CONSTRAINT "PK_e514921853e373c8b649e182f6b" PRIMARY KEY (id);


--
-- Name: user_opened_nodes PK_ee420f2ffeae5b0d530b3eee85e; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_opened_nodes
    ADD CONSTRAINT "PK_ee420f2ffeae5b0d530b3eee85e" PRIMARY KEY (id);


--
-- Name: community_statuses PK_ee8b63a87b31a40750defbe4e5b; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.community_statuses
    ADD CONSTRAINT "PK_ee8b63a87b31a40750defbe4e5b" PRIMARY KEY (id);


--
-- Name: learning_quiz_attempts PK_f86522c4fd814cb4c317ac3ffbb; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.learning_quiz_attempts
    ADD CONSTRAINT "PK_f86522c4fd814cb4c317ac3ffbb" PRIMARY KEY (id);


--
-- Name: user_opened_nodes UQ_3f3ca8f73945f2d18f1de1ab738; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_opened_nodes
    ADD CONSTRAINT "UQ_3f3ca8f73945f2d18f1de1ab738" UNIQUE ("userId", "nodeId");


--
-- Name: personal_mind_maps UQ_54278701a08afc9db9584142e9f; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personal_mind_maps
    ADD CONSTRAINT "UQ_54278701a08afc9db9584142e9f" UNIQUE ("userId", "subjectId");


--
-- Name: community_status_reactions UQ_741a54c56fb5ea4618f98689932; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.community_status_reactions
    ADD CONSTRAINT "UQ_741a54c56fb5ea4618f98689932" UNIQUE ("statusId", "userId");


--
-- Name: user_currencies UQ_81c8c1a7711d9651c6d3158465c; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_currencies
    ADD CONSTRAINT "UQ_81c8c1a7711d9651c6d3158465c" UNIQUE ("userId");


--
-- Name: users UQ_97672ac88f789774dd47f7c8be3; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT "UQ_97672ac88f789774dd47f7c8be3" UNIQUE (email);


--
-- Name: user_premium UQ_a6d374df28ba8ef7def1ee541f8; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_premium
    ADD CONSTRAINT "UQ_a6d374df28ba8ef7def1ee541f8" UNIQUE ("userId");


--
-- Name: payments UQ_c39d78e8744809ece8ca95730e2; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT "UQ_c39d78e8744809ece8ca95730e2" UNIQUE ("transactionId");


--
-- Name: achievements UQ_cd74882f69ff37d7330e89c63d5; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.achievements
    ADD CONSTRAINT "UQ_cd74882f69ff37d7330e89c63d5" UNIQUE (code);


--
-- Name: payments UQ_f413d3e1824c684723da101cad6; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT "UQ_f413d3e1824c684723da101cad6" UNIQUE ("paymentCode");


--
-- Name: test_embeddings test_embeddings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_embeddings
    ADD CONSTRAINT test_embeddings_pkey PRIMARY KEY (id);


--
-- Name: IDX_02e6f48b90b8af316214412912; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_02e6f48b90b8af316214412912" ON public.direct_messages USING btree ("senderId", "receiverId", "createdAt");


--
-- Name: IDX_077dc1d251deffa8e8d0ba1f80; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_077dc1d251deffa8e8d0ba1f80" ON public.user_badges USING btree ("userId", code);


--
-- Name: IDX_14e0035c6831c4de7c22fc66d7; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_14e0035c6831c4de7c22fc66d7" ON public.user_opened_nodes USING btree ("userId");


--
-- Name: IDX_1a9c562b804e524f8c100c23fc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_1a9c562b804e524f8c100c23fc" ON public.weekly_reward_history USING btree ("userId", "weekCode");


--
-- Name: IDX_1af87da88e1973ca35f936d594; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "IDX_1af87da88e1973ca35f936d594" ON public.user_topic_progress USING btree ("userId", "topicId");


--
-- Name: IDX_3048b98e79ecca7a16763ffa69; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_3048b98e79ecca7a16763ffa69" ON public.user_progress USING btree ("userId", "isCompleted");


--
-- Name: IDX_3899b7199ecc017491a058ed70; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "IDX_3899b7199ecc017491a058ed70" ON public.user_quests USING btree ("userId", "questId", date);


--
-- Name: IDX_3cb40ef800f65878970a1f1678; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_3cb40ef800f65878970a1f1678" ON public.self_leadership_checkins USING btree ("userId", "createdAt");


--
-- Name: IDX_4b8c5927e2d43be1f9d5a83f5d; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_4b8c5927e2d43be1f9d5a83f5d" ON public.self_leadership_checkins USING btree ("userId", "weekStart");


--
-- Name: IDX_57d42553196cf74cfef154a19c; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_57d42553196cf74cfef154a19c" ON public.user_unlocks USING btree ("userId", "unlockLevel", "subjectId");


--
-- Name: IDX_5a244161bb40f0d211a867736e; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "IDX_5a244161bb40f0d211a867736e" ON public.knowledge_edges USING btree ("fromNodeId", "toNodeId", type);


--
-- Name: IDX_5e9210b4560e083026af787ec3; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_5e9210b4560e083026af787ec3" ON public.payments USING btree ("userId", status);


--
-- Name: IDX_75ace3cab6c56196e1f282f9ae; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_75ace3cab6c56196e1f282f9ae" ON public.learning_nodes USING btree ("subjectId");


--
-- Name: IDX_7788c9673e3bf8e65e2522157e; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_7788c9673e3bf8e65e2522157e" ON public.learning_communication_attempts USING btree ("userId", "createdAt");


--
-- Name: IDX_79dcf5007c58853f82bacf3260; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_79dcf5007c58853f82bacf3260" ON public.learning_quiz_attempts USING btree ("userId", "nodeId", "lessonType");


--
-- Name: IDX_7f64b460e88d6292839de56e34; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_7f64b460e88d6292839de56e34" ON public.user_unlocks USING btree ("userId", "unlockLevel", "topicId");


--
-- Name: IDX_802177590e2ecd62d139508d16; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_802177590e2ecd62d139508d16" ON public.lesson_type_content_versions USING btree ("nodeId", "lessonType");


--
-- Name: IDX_9821d34ef16e19ab7510ba85ff; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_9821d34ef16e19ab7510ba85ff" ON public.reward_transactions USING btree ("userId", "createdAt");


--
-- Name: IDX_9dd1863abb66e7fc1bdcf8b36f; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_9dd1863abb66e7fc1bdcf8b36f" ON public.learning_quiz_attempts USING btree ("userId", "createdAt");


--
-- Name: IDX_a6f359922fb93e42d1b2daf38d; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_a6f359922fb93e42d1b2daf38d" ON public.chat_messages USING btree ("createdAt");


--
-- Name: IDX_ade36bd8b1045876146021e9e1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_ade36bd8b1045876146021e9e1" ON public.user_unlocks USING btree ("userId", "unlockLevel", "domainId");


--
-- Name: IDX_ae267b922c295ac548dd498e54; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "IDX_ae267b922c295ac548dd498e54" ON public.friendships USING btree ("requesterId", "addresseeId");


--
-- Name: IDX_b17bf7103df9dcf10e7022501d; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "IDX_b17bf7103df9dcf10e7022501d" ON public.lesson_type_contents USING btree ("nodeId", "lessonType");


--
-- Name: IDX_b36789a20daf2195986fddaec4; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_b36789a20daf2195986fddaec4" ON public.weekly_reward_history USING btree ("weekCode", rank);


--
-- Name: IDX_be8bf1bb5b55915dfb35cca477; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_be8bf1bb5b55915dfb35cca477" ON public.user_behaviors USING btree ("userId", "nodeId", "createdAt");


--
-- Name: IDX_c1acd69cf91b1e353634c152dd; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "IDX_c1acd69cf91b1e353634c152dd" ON public.user_achievements USING btree ("userId", "achievementId");


--
-- Name: IDX_d9917fe0070b42f2164d581abf; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "IDX_d9917fe0070b42f2164d581abf" ON public.user_weekly_plans USING btree ("userId", "weekStart");


--
-- Name: IDX_db9e96bbed60e162aac221d403; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "IDX_db9e96bbed60e162aac221d403" ON public.user_progress USING btree ("userId", "nodeId");


--
-- Name: IDX_dbc12effe9287d3002ea1b360a; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "IDX_dbc12effe9287d3002ea1b360a" ON public.user_domain_progress USING btree ("userId", "domainId");


--
-- Name: IDX_e3807f05ac57e287d13cd4fbd5; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "IDX_e3807f05ac57e287d13cd4fbd5" ON public.roadmap_days USING btree ("roadmapId", "dayNumber");


--
-- Name: IDX_f0364666aeafe33cf3adcc53fe; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_f0364666aeafe33cf3adcc53fe" ON public.friend_activities USING btree ("userId", "createdAt");


--
-- Name: IDX_f5fdcd299bef5ccc8e1f6db38e; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IDX_f5fdcd299bef5ccc8e1f6db38e" ON public.learning_communication_attempts USING btree ("userId", "nodeId", "lessonType");


--
-- Name: IDX_fc74151c76df192714f76b2a2e; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "IDX_fc74151c76df192714f76b2a2e" ON public.user_blocks USING btree ("blockerId", "blockedId");


--
-- Name: unlock_transactions FK_02d2ae8d3385514a0cd2cc53a49; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.unlock_transactions
    ADD CONSTRAINT "FK_02d2ae8d3385514a0cd2cc53a49" FOREIGN KEY ("userId") REFERENCES public.users(id);


--
-- Name: unlock_transactions FK_04737d53d7964e4f53795c29475; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.unlock_transactions
    ADD CONSTRAINT "FK_04737d53d7964e4f53795c29475" FOREIGN KEY ("subjectId") REFERENCES public.subjects(id);


--
-- Name: roadmaps FK_07bcaf715c0cad376aca1e96555; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roadmaps
    ADD CONSTRAINT "FK_07bcaf715c0cad376aca1e96555" FOREIGN KEY ("subjectId") REFERENCES public.subjects(id);


--
-- Name: placement_tests FK_0f8780d89101ef496ab4dae3fe9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.placement_tests
    ADD CONSTRAINT "FK_0f8780d89101ef496ab4dae3fe9" FOREIGN KEY ("userId") REFERENCES public.users(id);


--
-- Name: user_topic_progress FK_137c442b00194e02afe84998b68; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_topic_progress
    ADD CONSTRAINT "FK_137c442b00194e02afe84998b68" FOREIGN KEY ("topicId") REFERENCES public.topics(id) ON DELETE CASCADE;


--
-- Name: chat_messages FK_17a42899ce72cd55dc25fb33139; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT "FK_17a42899ce72cd55dc25fb33139" FOREIGN KEY ("replyToId") REFERENCES public.chat_messages(id) ON DELETE SET NULL;


--
-- Name: user_blocks FK_18d34df8212648b698828f244fb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_blocks
    ADD CONSTRAINT "FK_18d34df8212648b698828f244fb" FOREIGN KEY ("blockedId") REFERENCES public.users(id);


--
-- Name: user_behaviors FK_23a1a30653a907b0873927fc2d3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_behaviors
    ADD CONSTRAINT "FK_23a1a30653a907b0873927fc2d3" FOREIGN KEY ("nodeId") REFERENCES public.learning_nodes(id) ON DELETE CASCADE;


--
-- Name: placement_tests FK_25a32f8e4e96b14eb99245499b9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.placement_tests
    ADD CONSTRAINT "FK_25a32f8e4e96b14eb99245499b9" FOREIGN KEY ("subjectId") REFERENCES public.subjects(id);


--
-- Name: user_quests FK_262f95135c66a0fcf56a1c7f118; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_quests
    ADD CONSTRAINT "FK_262f95135c66a0fcf56a1c7f118" FOREIGN KEY ("questId") REFERENCES public.quests(id);


--
-- Name: reward_transactions FK_2715dd04b02293a5eb765509218; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reward_transactions
    ADD CONSTRAINT "FK_2715dd04b02293a5eb765509218" FOREIGN KEY ("userId") REFERENCES public.users(id);


--
-- Name: roadmaps FK_29f718c5a5cb41f2266d21ba207; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roadmaps
    ADD CONSTRAINT "FK_29f718c5a5cb41f2266d21ba207" FOREIGN KEY ("userId") REFERENCES public.users(id);


--
-- Name: user_behaviors FK_2faa3a577b9bed8e5d849a47f00; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_behaviors
    ADD CONSTRAINT "FK_2faa3a577b9bed8e5d849a47f00" FOREIGN KEY ("userId") REFERENCES public.users(id);


--
-- Name: user_achievements FK_3ac6bc9da3e8a56f3f7082012dd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_achievements
    ADD CONSTRAINT "FK_3ac6bc9da3e8a56f3f7082012dd" FOREIGN KEY ("userId") REFERENCES public.users(id);


--
-- Name: pending_contributions FK_3d78c39b2c03a08e8eb91f5135c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pending_contributions
    ADD CONSTRAINT "FK_3d78c39b2c03a08e8eb91f5135c" FOREIGN KEY ("contributorId") REFERENCES public.users(id);


--
-- Name: chat_messages FK_43d968962b9e24e1e3517c0fbff; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT "FK_43d968962b9e24e1e3517c0fbff" FOREIGN KEY ("userId") REFERENCES public.users(id);


--
-- Name: roadmap_days FK_43da70c0b7ceb981fdce5c7eedf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roadmap_days
    ADD CONSTRAINT "FK_43da70c0b7ceb981fdce5c7eedf" FOREIGN KEY ("nodeId") REFERENCES public.learning_nodes(id);


--
-- Name: roadmap_days FK_457ecdaa29491dd8306877789a6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roadmap_days
    ADD CONSTRAINT "FK_457ecdaa29491dd8306877789a6" FOREIGN KEY ("roadmapId") REFERENCES public.roadmaps(id);


--
-- Name: community_statuses FK_4660ad20f90f3f2cc02bcc73c22; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.community_statuses
    ADD CONSTRAINT "FK_4660ad20f90f3f2cc02bcc73c22" FOREIGN KEY ("userId") REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: learning_nodes FK_493fc8d1db322dcd5c11b031cef; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.learning_nodes
    ADD CONSTRAINT "FK_493fc8d1db322dcd5c11b031cef" FOREIGN KEY ("topicId") REFERENCES public.topics(id);


--
-- Name: lesson_type_content_versions FK_4ea37da8663b8e29bdb48f868e2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lesson_type_content_versions
    ADD CONSTRAINT "FK_4ea37da8663b8e29bdb48f868e2" FOREIGN KEY ("nodeId") REFERENCES public.learning_nodes(id) ON DELETE CASCADE;


--
-- Name: friendships FK_4f47ed519abe1ced044af260420; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.friendships
    ADD CONSTRAINT "FK_4f47ed519abe1ced044af260420" FOREIGN KEY ("requesterId") REFERENCES public.users(id);


--
-- Name: learning_nodes FK_574ad1e8f402b2913f8e652c93e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.learning_nodes
    ADD CONSTRAINT "FK_574ad1e8f402b2913f8e652c93e" FOREIGN KEY ("domainId") REFERENCES public.domains(id);


--
-- Name: direct_messages FK_6016910bebd28da423db80c6261; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.direct_messages
    ADD CONSTRAINT "FK_6016910bebd28da423db80c6261" FOREIGN KEY ("replyToId") REFERENCES public.direct_messages(id) ON DELETE SET NULL;


--
-- Name: community_status_reactions FK_64f1ac8da12def11b9b511e1593; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.community_status_reactions
    ADD CONSTRAINT "FK_64f1ac8da12def11b9b511e1593" FOREIGN KEY ("userId") REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: personal_mind_maps FK_6769c65f9373018aa67e7ef5de1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personal_mind_maps
    ADD CONSTRAINT "FK_6769c65f9373018aa67e7ef5de1" FOREIGN KEY ("subjectId") REFERENCES public.subjects(id);


--
-- Name: user_items FK_6a54ee9674f49de71669f7b9dc7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_items
    ADD CONSTRAINT "FK_6a54ee9674f49de71669f7b9dc7" FOREIGN KEY ("userId") REFERENCES public.users(id);


--
-- Name: user_achievements FK_6a5a5816f54d0044ba5f3dc2b74; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_achievements
    ADD CONSTRAINT "FK_6a5a5816f54d0044ba5f3dc2b74" FOREIGN KEY ("achievementId") REFERENCES public.achievements(id);


--
-- Name: user_badges FK_7043fd1cb64ec3f5ebdb878966c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_badges
    ADD CONSTRAINT "FK_7043fd1cb64ec3f5ebdb878966c" FOREIGN KEY ("userId") REFERENCES public.users(id);


--
-- Name: community_status_comments FK_714e3ab844f026facc26ffb41bc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.community_status_comments
    ADD CONSTRAINT "FK_714e3ab844f026facc26ffb41bc" FOREIGN KEY ("userId") REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: learning_nodes FK_75ace3cab6c56196e1f282f9ae6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.learning_nodes
    ADD CONSTRAINT "FK_75ace3cab6c56196e1f282f9ae6" FOREIGN KEY ("subjectId") REFERENCES public.subjects(id);


--
-- Name: direct_messages FK_7aedd4c96c0e01b95b87b8cea5a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.direct_messages
    ADD CONSTRAINT "FK_7aedd4c96c0e01b95b87b8cea5a" FOREIGN KEY ("senderId") REFERENCES public.users(id);


--
-- Name: user_domain_progress FK_7c77fde0ad7268ba2acd32b243b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_domain_progress
    ADD CONSTRAINT "FK_7c77fde0ad7268ba2acd32b243b" FOREIGN KEY ("domainId") REFERENCES public.domains(id) ON DELETE CASCADE;


--
-- Name: user_currencies FK_81c8c1a7711d9651c6d3158465c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_currencies
    ADD CONSTRAINT "FK_81c8c1a7711d9651c6d3158465c" FOREIGN KEY ("userId") REFERENCES public.users(id);


--
-- Name: user_progress FK_825aa4836c9f22e10f99956de22; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_progress
    ADD CONSTRAINT "FK_825aa4836c9f22e10f99956de22" FOREIGN KEY ("nodeId") REFERENCES public.learning_nodes(id) ON DELETE CASCADE;


--
-- Name: user_domain_progress FK_83bcccac75df7b9c4e2e58a0d90; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_domain_progress
    ADD CONSTRAINT "FK_83bcccac75df7b9c4e2e58a0d90" FOREIGN KEY ("userId") REFERENCES public.users(id);


--
-- Name: personal_mind_maps FK_891aacc6f7701f17f75faff2fbc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personal_mind_maps
    ADD CONSTRAINT "FK_891aacc6f7701f17f75faff2fbc" FOREIGN KEY ("userId") REFERENCES public.users(id);


--
-- Name: adaptive_tests FK_8c3807e3a37322914d467914e82; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adaptive_tests
    ADD CONSTRAINT "FK_8c3807e3a37322914d467914e82" FOREIGN KEY ("userId") REFERENCES public.users(id);


--
-- Name: user_unlocks FK_8e7e21243468972735dbe91d3bd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_unlocks
    ADD CONSTRAINT "FK_8e7e21243468972735dbe91d3bd" FOREIGN KEY ("userId") REFERENCES public.users(id);


--
-- Name: weekly_reward_history FK_91e6352ba5f3c23c2561d6726d4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.weekly_reward_history
    ADD CONSTRAINT "FK_91e6352ba5f3c23c2561d6726d4" FOREIGN KEY ("userId") REFERENCES public.users(id);


--
-- Name: domains FK_a4916b7bce3f00ede64b2984888; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.domains
    ADD CONSTRAINT "FK_a4916b7bce3f00ede64b2984888" FOREIGN KEY ("subjectId") REFERENCES public.subjects(id);


--
-- Name: user_premium FK_a6d374df28ba8ef7def1ee541f8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_premium
    ADD CONSTRAINT "FK_a6d374df28ba8ef7def1ee541f8" FOREIGN KEY ("userId") REFERENCES public.users(id);


--
-- Name: community_status_reactions FK_ac714d952013abe4f36b7d417bb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.community_status_reactions
    ADD CONSTRAINT "FK_ac714d952013abe4f36b7d417bb" FOREIGN KEY ("statusId") REFERENCES public.community_statuses(id) ON DELETE CASCADE;


--
-- Name: user_progress FK_b5d0e1b57bc6c761fb49e79bf89; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_progress
    ADD CONSTRAINT "FK_b5d0e1b57bc6c761fb49e79bf89" FOREIGN KEY ("userId") REFERENCES public.users(id);


--
-- Name: knowledge_edges FK_c0638604791c9ce9091c8d643cf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_edges
    ADD CONSTRAINT "FK_c0638604791c9ce9091c8d643cf" FOREIGN KEY ("toNodeId") REFERENCES public.knowledge_nodes(id);


--
-- Name: direct_messages FK_c13c61aa642b3debd5c2c53bbbd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.direct_messages
    ADD CONSTRAINT "FK_c13c61aa642b3debd5c2c53bbbd" FOREIGN KEY ("receiverId") REFERENCES public.users(id);


--
-- Name: friend_activities FK_c1baf95c9ed9d75ff2c541479ca; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.friend_activities
    ADD CONSTRAINT "FK_c1baf95c9ed9d75ff2c541479ca" FOREIGN KEY ("userId") REFERENCES public.users(id);


--
-- Name: friendships FK_c6ee540bba37d2b09b12dddd282; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.friendships
    ADD CONSTRAINT "FK_c6ee540bba37d2b09b12dddd282" FOREIGN KEY ("addresseeId") REFERENCES public.users(id);


--
-- Name: topics FK_c964b0bbd4c55e3dc708b93893d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.topics
    ADD CONSTRAINT "FK_c964b0bbd4c55e3dc708b93893d" FOREIGN KEY ("domainId") REFERENCES public.domains(id) ON DELETE CASCADE;


--
-- Name: payments FK_d35cb3c13a18e1ea1705b2817b1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT "FK_d35cb3c13a18e1ea1705b2817b1" FOREIGN KEY ("userId") REFERENCES public.users(id);


--
-- Name: knowledge_edges FK_d80623d315b4ae5cc4033224db3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_edges
    ADD CONSTRAINT "FK_d80623d315b4ae5cc4033224db3" FOREIGN KEY ("fromNodeId") REFERENCES public.knowledge_nodes(id);


--
-- Name: questions FK_e01d35c31e3ade999d9e569b79f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT "FK_e01d35c31e3ade999d9e569b79f" FOREIGN KEY ("subjectId") REFERENCES public.subjects(id);


--
-- Name: community_status_comments FK_e2576bfa18b577eb14faa36303c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.community_status_comments
    ADD CONSTRAINT "FK_e2576bfa18b577eb14faa36303c" FOREIGN KEY ("statusId") REFERENCES public.community_statuses(id) ON DELETE CASCADE;


--
-- Name: user_blocks FK_eae09d4f95afa5ae30c28384607; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_blocks
    ADD CONSTRAINT "FK_eae09d4f95afa5ae30c28384607" FOREIGN KEY ("blockerId") REFERENCES public.users(id);


--
-- Name: user_quests FK_f489a5a5d968cfb35e44815fbd9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_quests
    ADD CONSTRAINT "FK_f489a5a5d968cfb35e44815fbd9" FOREIGN KEY ("userId") REFERENCES public.users(id);


--
-- Name: adaptive_tests FK_f56f26f2c85a8b29983959444b7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adaptive_tests
    ADD CONSTRAINT "FK_f56f26f2c85a8b29983959444b7" FOREIGN KEY ("subjectId") REFERENCES public.subjects(id);


--
-- Name: user_topic_progress FK_f6b8a4b2da38741b6d3e45bb9b5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_topic_progress
    ADD CONSTRAINT "FK_f6b8a4b2da38741b6d3e45bb9b5" FOREIGN KEY ("userId") REFERENCES public.users(id);


--
-- Name: lesson_type_contents FK_f9aac63aa6183c2183971d5c04b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lesson_type_contents
    ADD CONSTRAINT "FK_f9aac63aa6183c2183971d5c04b" FOREIGN KEY ("nodeId") REFERENCES public.learning_nodes(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--


