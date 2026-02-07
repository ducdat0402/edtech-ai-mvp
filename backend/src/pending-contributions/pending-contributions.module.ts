import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PendingContribution } from './entities/pending-contribution.entity';
import { PendingContributionsService } from './pending-contributions.service';
import { PendingContributionsController } from './pending-contributions.controller';
import { UsersModule } from '../users/users.module';
import { SubjectsModule } from '../subjects/subjects.module';
import { DomainsModule } from '../domains/domains.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([PendingContribution]),
    UsersModule,
    SubjectsModule,
    forwardRef(() => DomainsModule),
  ],
  controllers: [PendingContributionsController],
  providers: [PendingContributionsService],
  exports: [PendingContributionsService],
})
export class PendingContributionsModule {}
