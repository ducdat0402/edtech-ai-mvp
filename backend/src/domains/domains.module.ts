import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DomainsService } from './domains.service';
import { DomainsController } from './domains.controller';
import { Domain } from './entities/domain.entity';
import { SubjectsModule } from '../subjects/subjects.module';
import { LearningNodesModule } from '../learning-nodes/learning-nodes.module';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Domain]),
    forwardRef(() => SubjectsModule),
    forwardRef(() => LearningNodesModule),
    UsersModule, // Required for AdminGuard
  ],
  controllers: [DomainsController],
  providers: [DomainsService],
  exports: [DomainsService],
})
export class DomainsModule {}

